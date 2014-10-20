/**
 * Describe Salesforce object to be used in the app. For example: Below AngularJS factory shows how to describe and
 * create an 'Contact' object. And then set its type, fields, where-clause etc.
 *
 *  PS: This module is injected into ListCtrl, EditCtrl etc. controllers to further consume the object.
 */
angular.module('Contact', []).factory('Contact', function (AngularForceObjectFactory) {
    //Describe the contact object
    var objDesc = {
        type: 'Contact',
        fields: ['Name', 'FirstName', 'LastName', 'Title', 'Phone', 'Email', 'Id', 'Account.Name'],
        where: '',
        orderBy: 'LastName',
        limit: 20
    };
    var Contact = AngularForceObjectFactory(objDesc);

    // Cache for type-ahead queries. We keep up to 10 queries.
    Contact.queryCache = new LRUCache(10); 

    return Contact;
});

/**
 * Maintain the state of the ContactList page when navigating to and from the ContactView page.
 */
angular.module('SearchContext', []).factory('SearchContext', function () {
    var currentState = null;

    return {
        invalidateState: function () {
            currentState = null;
        },
        hasState: function () {
            return currentState != null;
        },
        saveState: function (scope) {
            currentState = {
            	contactsTypeAhead: scope.contactsTypeAhead,
            	searchTerm: scope.searchTerm,
            	showMru: scope.showMru,
            	showTypeAhead: scope.showTypeAhead,
            	showRegularSearch: scope.showRegularSearch
            };
            
        },
        restoreState: function (scope) {
            scope.contactsTypeAhead = currentState.contactsTypeAhead;
            scope.searchTerm = currentState.searchTerm;
            scope.showMru = currentState.showMru;
            scope.showTypeAhead = currentState.showTypeAhead;
            scope.showRegularSearch = currentState.showRegularSearch;
        }
    };
});

function HomeCtrl($scope, AngularForce, $location, $route) {
    var isOnline =  AngularForce.isOnline();
    var isAuthenticated = AngularForce.authenticated();

    //Offline support (only for Cordova)
    //First check if we are online, then check if we are already authenticated (usually happens in Cordova),
    //If Both online and authenticated(Cordova), go directly to /contacts view. Else show login page.
    if(!isOnline) {
        if(!isAuthenticated) {//MobileWeb
            return $location.path('/login');
        } else {//Cordova
            return $location.path('/contactsHome/');
        }
    }

    //If in visualforce, directly login
    if (AngularForce.inVisualforce) {
        //$location.path('/login');
        AngularForce.login(function() {
            $location.path('/contactsHome/');
        });
    } else if (AngularForce.refreshToken) { //If web, try to relogin using refresh-token
        AngularForce.login(function () {
            $location.path('/contactsHome/');
            $scope.$apply();//Required coz sfdc uses jquery.ajax
        });
    } else {
        $location.path('/login');
    }
}

function LoginCtrl($scope, AngularForce, $location) {
    //Usually happens in Cordova
    if (AngularForce.authenticated()) {
        return $location.path('/contactsHome/');
    }

    $scope.login = function () {
        //If in visualforce, 'login' = initialize entity framework
        if (AngularForce.inVisualforce) {
            AngularForce.login(function() {
                $location.path('/contactsHome/');
            });
        } else {
            AngularForce.login();
        }
    };

    $scope.isLoggedIn = function () {
        return AngularForce.authenticated();
    };

    $scope.logout = function () {
        AngularForce.logout(function () {
            //Now go to logout page
            $location.path('/logout');
            $scope.$apply();
        });
    };
}

function CallbackCtrl($scope, AngularForce, $location) {
    AngularForce.oauthCallback(document.location.href);

    //Note: Set hash to empty before setting path to /contacts to keep the url clean w/o oauth info.
    //..coz oauth CB returns access_token in its own hash making it two hashes (1 from angular,
    // and another from oauth)
    $location.hash('');
    $location.path('/contacts');
}

function ContactHomeCtrl($scope, AngularForce, SearchContext, $location, Contact) {
    if (!AngularForce.authenticated()) {
        return $location.path('/home');
    }
    SearchContext.invalidateState();

    $scope.gotoSearch = function () {
        $location.path('/contacts/');
        $scope.slideDirection = 'slideRtoL';
        console.log('the slide direction is ', $scope.slideDirection);
    };
}


function ContactListCtrl($scope, $rootScope, AngularForce, SearchContext, $location, Contact) {
    // Hack: this is a hack so that we have pictures for the demo. In a real application, one should use the image associated
    // to the contact 'social network' account. This was not convenient to upload many contact for the demo context.
    $scope.hasPhoto = function(person) {
        var contactsPhotos = ['Chet Baker', 'Dizzy Gillespie', 'John Coltrane', 'Louis Armstrong', 'Miles Davis', 'Wes Montgomery', 'Wynton Marsalis'];
        return _.contains(contactsPhotos, person.Name);
    };

    $scope.contactName = function(person) {
        return person.Name.split(' ').join('');
    };
    // End hack.

    if (!AngularForce.authenticated()) {
        return $location.path('/home');
    }

    $scope.working = false;
    $scope.typeaheadState = {lastRequestTime:0, lastSearchTerm:''};

    if (SearchContext.hasState()) {
        SearchContext.restoreState($scope);
    } else {
        $scope.searchTerm = '';
        $scope.showRegularSearch = false;
        $scope.showMru = true;
        $scope.showTypeAhead = false;
    }

    Contact.mru(function (data) {
        $scope.contactsMru = data.records;
        $scope.$apply();//Required coz sfdc uses jquery.ajax
    }, function (data) {
    });


    $scope.isWorking = function () {
        return $scope.working;
    };

    $scope.doCancel = function () {
        $scope.contactsTypeAhead = [];
        $location.path('/contactsHome/');
        $scope.$apply();//Required coz sfdc uses jquery.ajax
    };

    $scope.eraseTerms = function () {
        $scope.contactsTypeAhead = [];
        $scope.searchTerm = "";
        $scope.showMru = true;
        $scope.showTypeAhead = false;
        $scope.showRegularSearch = false;
        SearchContext.saveState($scope);
        $scope.$apply();//Required coz sfdc uses jquery.ajax
    };

    $scope.goBack = function() {
        $scope.contactsTypeAhead = [];
    };

    $scope.doSearch = function () {
        Contact.search($scope.searchTerm, function (data) { // This is the contact search success callback.
            $scope.contactsTypeAhead = data;
            $scope.showRegularSearch = true;
            $scope.showMru = false;
            $scope.showTypeAhead = false;
            SearchContext.saveState($scope);

            $scope.$apply();//Required coz sfdc uses jquery.ajax
        }, function (data) {
        });
    };

    $scope.doSuggest = function () {

        var fetchAndUpdate = function () {
            $scope.lastQueryInExecution = $scope.searchTerm;
            query = $scope.searchTerm;
            Contact.suggest($scope.searchTerm, 'Contact', 5, function (data) {
                $scope.contactsTypeAhead = data.autoSuggestResults;
                $scope.showRegularSearch = false;
                $scope.showMru = false;
                $scope.showTypeAhead = true;
                SearchContext.saveState($scope);
                $scope.$apply();//Required coz sfdc uses jquery.ajax
                Contact.queryCache.put(query, data.autoSuggestResults);
		        $scope.typeaheadState.lastRequestTime = new Date().getTime();
                
            }, function (data) {
            });
        };

        if ($scope.searchTerm.trim().length == 0) {
            $scope.showRegularSearch = false;
            $scope.showMru = true;
            $scope.showTypeAhead = false;
            SearchContext.saveState($scope);
            return;
        }

        // Don't issue a query if it is less than 3 characters
        if ($scope.searchTerm.trim().length < 3) {
            return;
        }

        // Check if we already have the query in the cache
        var cachedEntry = Contact.queryCache.get($scope.searchTerm.trim());
        if (cachedEntry != null) {
            $scope.contactsTypeAhead = cachedEntry;
            $scope.showRegularSearch = false;
            $scope.showMru = false;
            $scope.showTypeAhead = true;
            SearchContext.saveState($scope);
            $scope.$apply();//Required coz sfdc uses jquery.ajax
            return;
        }

        // Don't issue queries more than 1 per 300 ms.
        var time = new Date().getTime();
        var nextQueryDelay = 200 - Math.min(time - $scope.typeaheadState.lastRequestTime, 300);

        //console.log('query:' + $scope.searchTerm);
        //console.log('last query in execution:' + $scope.lastQueryInExecution);
        //console.log('next query delay:' + nextQueryDelay);
        //console.log('time:' + time);
        //console.log('previous time:' + $scope.typeaheadState.lastRequestTime);
        $scope.typeaheadState.lastRequestTime = new Date().getTime();
        if ($scope.delayedQuery) {
          //console.log('Delayed query in progress already');
          return;
        }
        if (nextQueryDelay > 0) { // enforce 300 ms between calls + only perform one delayed call at the same time.
            
            $scope.delayedQuery = true;
        
            var scope = $scope;
            setTimeout(function () {

                // if search terms are still the same, go ahead and retrieve the data, else another Timeout call will take care of it.
                if ($scope.lastQueryInExecution != $scope.searchTerm) {
                    //console.log('delayed fetch update');
                    fetchAndUpdate();
                } else {
                    //console.log('cancel delayed fetch update');
                }
                $scope.delayedQuery = false;
            }, nextQueryDelay);
            return;
        }
        //console.log('regular fetch update');
        fetchAndUpdate();
    };

    $scope.doView = function (contactId) {
        //console.log('doView');
        $location.path('/view/' + contactId);
    };

    $scope.doCreate = function () {
        $location.path('/new');
    }


}

function ContactCreateCtrl($scope, $location, Contact) {
    $scope.save = function () {
        Contact.save($scope.contact, function (contact) {
            var c = contact;
            $scope.$apply(function () {
                $location.path('/view/' + c.Id);
            });
        });
    }
}

function ContactViewCtrl($scope, AngularForce, $location, $routeParams, Contact) {

    AngularForce.login(function () {
        Contact.get({id: $routeParams.contactId}, function (contact) {
            self.original = contact;
            $scope.contact = new Contact(self.original);
            $scope.$apply();//Required coz sfdc uses jquery.ajax
        });
    });

    // Hack: this is a hack so that we have pictures for the demo. In a real application, one should use the image associated
    // to the contact 'social network' account. This was not convenient to upload many contact for the demo context.
    $scope.hasPhoto = function(person) {
        var contactsPhotos = ['Chet Baker', 'Dizzy Gillespie', 'John Coltrane', 'Louis Armstrong', 'Miles Davis', 'Wes Montgomery', 'Wynton Marsalis'];
        return (person && _.contains(contactsPhotos, person.Name));
    };
    // End hack.

}

function ContactDetailCtrl($scope, AngularForce, $location, $routeParams, Contact) {
    var self = this;

    if ($routeParams.contactId) {
        AngularForce.login(function () {
            Contact.get({id: $routeParams.contactId},
                function (contact) {
                    self.original = contact;
                    $scope.contact = new Contact(self.original);
                    $scope.$apply();//Required coz sfdc uses jquery.ajax
                });
        });
    } else {
        $scope.contact = new Contact();
        //$scope.$apply();
    }

    $scope.isClean = function () {
        return angular.equals(self.original, $scope.contact);
    }

    $scope.destroy = function () {
        self.original.destroy(
            function () {
                $scope.$apply(function () {
                    $location.path('/contacts');
                });
            },
            function (errors) {
                alert("Could not delete contact!\n" + JSON.parse(errors.responseText)[0].message);
            }
        );
    };

    $scope.save = function () {
        if ($scope.contact.Id) {
            $scope.contact.update(function () {
                $scope.$apply(function () {
                    $location.path('/view/' + $scope.contact.Id);
                });

            });
        } else {
            Contact.save($scope.contact, function (contact) {
                var c = contact;
                $scope.$apply(function () {
                    $location.path('/view/' + c.Id || c.id);
                });
            });
        }
    };

    $scope.doCancel = function () {
        if ($scope.contact.Id) {
            $location.path('/view/' + $scope.contact.Id);
        } else {
            $location.path('/contacts');
        }
    }
}
