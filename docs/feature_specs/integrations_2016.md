#### Integrations

<h4 style='color: red;'>DRAFT</h4>

**Updated: December 8, 2016**

**Work Estimate: 10-12**

#### QUESTIONS
- How do you envision the drag and drop working? 
  + Do users drag on top of a tip to upload to that tip?
  + Do users drag to an activation area to create a new tip?
  + I think giving them a target of some sort is needed
- Is the user presented with the three button? Or only after they connect?
  + If the three buttons don't pre-exist, do they click the ••• button to connect?
- Should we list folders as well as files?
  + If a user clicks a folder, do we then jump into that folder?
  + If a user clicks a file, what happens, if anything?

#### PURPOSE
- To increase activation by removing barriers to entry
- To provide access to a user's dropbox, box, google drive account
- To allow users to drag documents over an attach them to tips

#### DESCRIPTION
##### BEHAVIOR
- On the right side, there will be three buttons, one for each service
  + When they click a service, they will either be presented with a file view or option to connect
- After connecting, we should start listing files and folders at the top level
- The user may navigate through their stored files
- The user should be able to drag and drop a file onto TipHive
- Once the document is dropped, ask if they want to upload or link
- Auto detect if its an image or document and upload correctly

#### DEVELOPMENT THOUGHTS
##### API
- We need to save the post-authorization token with the user
- We need to initiate an upload when dragging a document/image over a Tip

##### FRONT END
- The majority of the work is here
- We need to devise a drag-n-drop strategy
  + Drag and Drop will be used for this feature
  + It will also be used to organize Tips and Subhives
  + Also, it will be used in the Finder View(Miller Columns)
  + There is this: <code>https://github.com/gaearon/react-dnd</code> 
    * Note there are 110 issues on the repo, but I don't know if they matter
- There is a new right action bar
  + <code>https://projects.invisionapp.com/d/main#/console/9694836/207426207/preview</code> 
- At the bottom there are buttons for the services we'll offer
- When you click DropBox, it will open a new Right Popover of some sort
  + <code>https://projects.invisionapp.com/d/main#/console/9694836/208055272/preview</code> 
- MORE MOCKUPS TO COME

##### POSSIBLE COMPONENTS
- **NOTE** these are just ideas, make sure we are thinking clearly about the components
- <code>< RightActionBar></code> 
  + This could be the foundational component for all actions, filters, integrations
- <code>< IntegrationsSection></code> 
  + This is the bottom container within the RightActionBar that wraps all the integrations
- <code>< IntegrationButton service='dropbox'></code> 
  + This might be an idea for each of the services to have their own button
  + The service prop could deterimine icon and behavior?
- <code>< IntegrationPopOver><c/ode>  
  + Probably a better word, this is the section that will slide in from the right
  + The user is presented a list of files an folders here
- <code>< Draggable>{children}</Draggable></code> 
  + A wrapper component that makes whatever is inside draggable as a unit
  + Use this to wrap each of the files that show up in the file list, so users can drag it out
- <code>< Folder></code> 
  + This component could wrap any folders that come in via the service
  + Folders could have some kind of action that changes the list to that new location
- <code>< SelectBox></code> 
  + This may be an existing component
  + It will need to list .... Waiting on answers from design
- <code>< SettingsGear></code> 
  + Another possible existing component
  + Opens the settings for the service ... Still getting clarification on this one
- <code>< Close></code> 
  + Some kind of component that closes the IntegrationPopOver

##### TESTS
- Given I am a user
  + And I open the dropbox integration
  + And I have not yet authorized TipHive to access my DropBox
  + Then I should see an option to connect to DropBox
  + Then I should see a list of my top level folders and files
- Given I am a user
  + And I open the dropbox integration
  + And I have already authorized TipHive to access my DropBox
  + Then I should see a list of my top level folders and files
- THE ABOVE TESTS SHOULD BE WRITTEN FOR Box and Google Drive as well
- Given I have my file list open from Dropbox
  + And I drag a file to an existing Tip
  + I should be presented an option to upload or link to the DropBox File
  + Given I choose upload
    * Then we should follow our standard upload flow
  + Given I choose link
    * Then we should create a special document with a "LINK" icon
    * This should appear as other docs do
    * When clicked, it should open the file in the originating service
- TODO: Test for draggable target area, if we have one
