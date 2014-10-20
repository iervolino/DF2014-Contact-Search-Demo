DF2014-Search-Contact-Demo
==========================
This application allows to quickly search through your Salesforce Contacts.

It has been implemented as a fully-functional demo for our DreamForce 2014 presentation: Best Practices for Search User Experience and Implementation

It showcases several search API and how to integrate them into a fluid User Experience.

#Install
This application is published as an unmanaged package at: https://login.salesforce.com/packaging/installPackage.apexp?p0=04tB000000010wZ

* Prerequisites:  Sign up for a free Salesforce Platform Developer Edition (DE), if you don’t already have one. This will act as your own isolated development and test environment. You should not use this tutorial with a trial, sandbox, or production org.
* Install the Application into your DE Org
  * Log into your DE
  * Paste this install URL into the address bar (or click the link) to start installing the package: https://login.salesforce.com/packaging/installPackage.apexp?p0=04tB000000010wZ
  * Click ‘Continue’ on the Package Installation Detail page
  * Click ‘Next’ for Step 1. Approve Package API Access
  * Choose the access level you want end users to have and then click ‘Next’ for Step 2. Choose security level (Grant access to all is recommended for a personal DE test environment)
  * Click ‘Install’ for Step 3. Install Package

#Develop
At some point, you may want to modify the application.

The first way to do this is to modify directly the pages in Salesforce online editor (Setup > Develop > Pages).

When you will want to modify javascript files, the most efficient way is probably to install 
Salesforce IDE (https://developer.salesforce.com/page/Force.com_IDE_Installation).

With that approach, you can deploy pages and static resources to your org with a single click.

Select the files, right-click > Force.com > Save to server.

#Content
* ./src/pages: Visual Source pages (i.e. HTML page with a few APEX variables
  * MobileSample_ngIndex.page: index pages that includes all the resources needed for this project.
  * MobileSample_ngHome.page: intermediate page used for redirection to login page
  * MobileSample_ngLogin.page: login page
  * MobileSample_ngContactHome.page: home page for the Contact application. Mainly a static page at this point.
  * MobileSample_ngContactList.page: page that display both MRU, Type-ahead results and Full-text results
  * MobileSample_ngContactView.page: display a Contact details
* ./src/staticresources: Javascript, CSS, fonts and images resources
  * smartsync_js.resource: used for offline mode. Not used in this demo (check out the original Mobile Pack for details).
  * angular_force_js.resource: wrapper javascript to expose Salesforce API in an angularjs friendly way
  * app_js.resource: Controller for the application (one method for each HTML page).
  * forcetk_mobilesdk_js.resource: generic client productivity for Salesforce REST API
  * init_js.resource: initialize AngularJS modules
  * vendor_zip.resource: zip of resources in the lib folder
* ./src/staticresources/lib: contains all the resources that are in vendor_zip.resource
  * css: CSS and font files
  * images: images for icons and some Contact pictures for the demo
  * js: javascript resources
  * vendor.zip: zip file for css+images+js. After changing files in the lib folder, you should zip everything in vendor.zip and copy it to vendor_zip.resource


#API
##Most Recently Used items
Implemented as a SOQL statement

Rest entry point: 
> /services/data/v32.0/query?q=...

Where 
> q=SELECT id, Name, Title, Account.Name FROM Contact USING SCOPE MRU ORDER BY LastViewedDate Desc LIMIT 6

(dutifully URL encoded of course)

##Search Suggested Records
> /services/data/v32.0/search/suggestions?sobject=Contact&q=foo

##SOSL: Full-text search
> /services/data/v32.0/search?q=…

Where:
> q=Find {foo} IN ALL FIELDS RETURNING Contact(Id, Name, Address)

(dutifully URL encoded of course)

#Limitations
* The Home page element are static HTML
* Some actions on the Contact details view are not implemented.

#Implementation
This demo is based on Mobile Pack AngularJS demo: https://github.com/developerforce/MobilePack-AngularJS

What I changed is:
* I added an entry point for the Search Suggested Record API in forcetk (the javascript productivity layer around salesforce.com
REST API). 
* I added methods for MRU and Search Suggested Records in angular-force.js and smartsync.js (I didn't really need smartsync, but that's what came with the Mobile pack sample).
* For the rest, this is basic angular application layout. We added pages, controller and CSS:
  * VF Pages are the HTML part (view part of angular)
  * app.js is the 'controller' part. Each HTML file has a corresponding javascript function/controller in app.js

#What the heck with these Visual Force pages?

The only reason for having these apex pages is to avoid hosting html/js/css in yet another
hosting environment.

The main caveat are these kind of statement:

```<link rel="stylesheet" href="{!URLFOR($Resource.vendor_zip, 'css/ssGizmo.css')}"/>```

What this mean is that the css file ssGizmo.css will be found in a static resource (check 
out the 'static resources' tab) named 'vendor_zip', which is a zip file. The second parameter
to the URLFOR function is the path inside this zip file.

If you were to host the pages as regular HTML pages outside force.com, you would have to change
these statement with relative URL.

#References
* Original Mobile pack: https://github.com/developerforce/MobilePack-AngularJS 
* SOSL and SOQL Reference Guide: http://www.salesforce.com/us/developer/docs/soql_sosl/
* REST API Developer’s Guide: http://www.salesforce.com/us/developer/docs/api_rest/api_rest.pdf 

To build this demo, we have used: [AngularJS](https://angularjs.org/), [JQuery](http://jquery.com/), [Bootstrap](http://getbootstrap.com/2.3.2/), [Gizmo fonts](https://symbolset.com/icons/gizmo)

#Authors
* Marc Brette
* JD Vogt
* Donielle Berg

