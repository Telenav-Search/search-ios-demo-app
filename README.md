# search-ios-demo-app

### Running Demo App

For running on physical device developer need to have correct Provisioning Profile and Signing Certificate.

1. Do `pod repo-art update telenav-cocoapods` if necessary
1. Do `pod install`
1. Modify the configuration file `SDKConfig.plist`, fill the correct ApiKey/ApiSecret/CloudEndpoint.
1. Run target TelenavDemo

### Archiving Demo App

For archiving developer need to have correct Provisioning Profile and Signing Certificate.

1. Do `pod repo-art update telenav-cocoapods` if necessary
1. Do `pod install`
1. Select target TelenavDemo.
1. Select device 'Any iOS Device ...'
1. Select menu Product -> Archive
1. When it finishes building, press Distribute in Organizer.
1. Select Ad Hoc or Enterprise, depending on your certificate.
1. Upload resulting archive to hosting. (f.e. diawi.com).
