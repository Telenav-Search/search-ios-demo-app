# search-ios-demo-app

### Install dependencies before opening the project:

1. You need [CocoaPods](https://cocoapods.org) and [cocoapods-art](https://github.com/jfrog/cocoapods-art) plugin to de installed:
    
    `sudo gem install cocoapods`

    `sudo gem install cocoapods-art`
    
    You can use this [Guide](https://guides.cocoapods.org/using/getting-started.html#getting-started) for installation.

2. If it is the first time you build Demo App, add Telenav Cocoapods repos. Do the following commands from the root folder of project:

    ```
    pod repo-art add telenav-cocoapods "https://telenav.jfrog.io/artifactory/api/pods/telenav-cocoapods"
    ```
    and
    ```
    pod repo-art add telenav-cocoapods-preprod-local "https://artifactory.telenav.com/api/pods/telenav-cocoapods-preprod-local"
    ```
        
    Else just update the repos:
    ```
    pod repo-art update telenav-cocoapods
    ``` 
    and 
    ```
    pod repo-art update telenav-cocoapods-preprod-local
    ```
        
3. Do `pod install`
4. Open `TelenavDemo.xcworkspace` file.

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
