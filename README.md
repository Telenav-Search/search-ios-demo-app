# search-ios-demo-app

### Install dependencies before openning the project:

1. If it is the first time you build Demo App, do the following commands from the root folder of project:
        `pod repo-art add telenav-cocoapods "https://telenav.jfrog.io/artifactory/api/pods/telenav-cocoapods"`
    and
        `pod repo-art add telenav-cocoapods-preprod-local "https://artifactory.telenav.com/api/pods/telenav-cocoapods-preprod-local"`
    
    Else just update the repos:
        `pod repo-art update telenav-cocoapods` 
    and 
        `pod repo-art update telenav-cocoapods-preprod-local`.
        
2. Do `pod install`
3. Open `TelenavDemo.xcworkspace` file.

### Running Demo App

For running on physical device developer need to have correct Provisioning Profile and Signing Certificate.

1. Modify the configuration file `SDKConfig.plist`, fill the correct `ApiKey/ApiSecret/CloudEndpoint`.
2. Run target TelenavDemo

### Archiving Demo App

For archiving developer need to have correct Provisioning Profile and Signing Certificate.

1. Modify the configuration file `SupportFiles/SDKConfig.plist`, fill the correct `ApiKey/ApiSecret/CloudEndpoint`.
2. Select target TelenavDemo.
3. Select device 'Any iOS Device ...'
4. Select menu Product -> Archive
5. When it finishes building, press Distribute in Organizer.
6. Select Ad Hoc or Enterprise, depending on your certificate.
7. Upload resulting archive to hosting. (f.e. diawi.com).
