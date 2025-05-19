#import "AcuantFlutterPlugin.h"
#if __has_include(<acuant_flutter_plugin/acuant_flutter_plugin-Swift.h>)
#import <acuant_flutter_plugin/acuant_flutter_plugin-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "acuant_flutter_plugin-Swift.h"
#endif

@implementation AcuantFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftAcuantFlutterPlugin registerWithRegistrar:registrar];
}
@end 