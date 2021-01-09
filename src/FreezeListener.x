#include <objc/runtime.h>
#include <dlfcn.h>
#import <libactivator/libactivator.h>
#import <stdlib.h>
#import <UIKit/UIKit.h>
#import <SpringBoard/SpringBoard.h>
#include <spawn.h>
#include <sys/sysctl.h>

static NSString *bundleID = @"com.p1atdev.freezaListener.freeze";
static LAActivator *_LASharedActivator;

@interface FreezaListener : NSObject <LAListener>

+ (id)sharedInstance;

@end

@interface SBApplicationProcessState
@property(readonly, nonatomic) _Bool isBeingDebugged;
@property(readonly, nonatomic) int visibility;
@property(readonly, nonatomic) int taskState;
@property(readonly, nonatomic, getter=isForeground) _Bool foreground;
@property(readonly, nonatomic, getter=isRunning) _Bool running;
@property(readonly, nonatomic) int pid;
@end


@interface SBApplication
@property(retain, getter=_internalProcessState, setter=_setInternalProcessState:) SBApplicationProcessState *internalProcessState;
@end
// @interface SBApplicationProcess
// @property(readonly, nonatomic, getter=isRunning) _Bool running;
// @property(readonly, nonatomic) int pid;
// @end

@interface SBApplicationController : NSObject
+ (id)sharedInstance;
- (id)applicationWithBundleIdentifier:(id)arg1;

@property NSString *badgeNumberOrString;
@end

@implementation FreezaListener

+ (instancetype)sharedInstance {
	static id sharedInstance = nil;
	static dispatch_once_t token = 0;
	dispatch_once(&token, ^{
		sharedInstance = [self new];
	});
	return sharedInstance;
}

+ (void)load {
	void *la = dlopen("/usr/lib/libactivator.dylib", RTLD_LAZY);
	if (!la) {
		// HBLogDebug(@"Failed to load libactivator");
		_LASharedActivator = nil;
	} else {
		_LASharedActivator = [objc_getClass("LAActivator") sharedInstance];
	}

	[self sharedInstance];
}

- (instancetype)init {
	if ([super init]) {
		// Register our listener
		if (_LASharedActivator) {
			if (![_LASharedActivator hasSeenListenerWithName:bundleID]) {
				[_LASharedActivator assignEvent:[objc_getClass("LAEvent") eventWithName:@"libactivator.volume.both.press"] toListenerWithName:bundleID];
			}
			if (_LASharedActivator.isRunningInsideSpringBoard) {
				[_LASharedActivator registerListener:self forName:bundleID];
			}
		}
	}
	return self;
}

- (void)dealloc {
	if (_LASharedActivator) {
		if (_LASharedActivator.runningInsideSpringBoard) {
			[_LASharedActivator unregisterListenerWithName:bundleID];
		}
	}
}

// Listener custom methods

- (BOOL)present {
	return NO;
}

- (BOOL)dismiss {
	return NO;
}

// LAListener protocol methods

- (void)activator:(LAActivator *)activator didChangeToEventMode:(NSString *)eventMode {
	[self dismiss];

}

// Incoming events

// Normal assigned events
- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event forListenerName:(NSString *)listenerName {
	// Called when we receive event

		//起動したアプリケーションのbundle
		NSString *identifier = LASharedActivator.displayIdentifierForCurrentApplication;

		//SBApplicationControllerからアプリケーションを特定
		Class $SBApplicationController = objc_getClass("SBApplicationController");
		SBApplication *application = [[$SBApplicationController sharedInstance] applicationWithBundleIdentifier:identifier];

		// SBApplication *application = [[SBApplicationController sharedInstance] applicationWithDisplayIdentifier:identifier];
		
		// SBApplicationProcessState *applicationProcessState = application.internalProcessState;
		
		//プロセスidを取得
		int pid = application.internalProcessState.pid;

		//動くか取得
		// BOOL isRunning = application.internalProcessState.running;

		// //ステータスを取得
		// int status = application.internalProcessState.taskState;

		//アプリが動いているなら止める、止まってたら再開する
		system((char *)[[NSString stringWithFormat:@"kill -STOP %i", pid] UTF8String]);

		//MARK: アラートを出す処理
		//親ビューを生成
		// UIViewController *view = [UIApplication sharedApplication].keyWindow.rootViewController;
        // while (view.presentedViewController != nil && !view.presentedViewController.isBeingDismissed) {
        //         view = view.presentedViewController;
        // }
		
		// //アラートコントローラーを作成
		// UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Freeza Action" 
		// 							message: [ NSString stringWithFormat: @"Application: %@\nPID: %d\nStatus: %i\nisRunning: %hhd", identifier, pid, status, isRunning]
		// 							preferredStyle:UIAlertControllerStyleAlert];

		// [alert addAction:[UIAlertAction actionWithTitle:@"OK" 
        //                                                 style:UIAlertActionStyleDefault 
        //                                               handler:^(UIAlertAction *action) {
        // //ボタンが押された時の処理                                                      
    	// }]];

		// //プレゼント
		// [view presentViewController:alert animated:YES completion:nil];

		// int returnCode = system([ NSString stringWithFormat: @"/usr/bin/ %@", identifier ]);


	if ([self present]) {
		//実行
		[event setHandled:YES];
	}
}
// Sent when a chorded event gets escalated (short hold becoems a long hold, for example)
- (void)activator:(LAActivator *)activator abortEvent:(LAEvent *)event forListenerName:(NSString *)listenerName {
	// Called when event is escalated to a higher event
	// (short-hold sleep button becomes long-hold shutdown menu, etc)
	[self dismiss];
}
// Sent at the lock screen when listener is not compatible with event, but potentially is able to unlock the screen to handle it
- (BOOL)activator:(LAActivator *)activator receiveUnlockingDeviceEvent:(LAEvent *)event forListenerName:(NSString *)listenerName {
	// return YES if this listener handles unlocking the device
	return NO;
}
// Sent when the menu button is pressed. Only handle if you want to suppress the standard menu button behaviour!
- (void)activator:(LAActivator *)activator receiveDeactivateEvent:(LAEvent *)event {
	// Called when the home button is pressed.
	// If (and only if) we are showing UI, we should dismiss it and call setHandled:
	if ([self dismiss]) {
		[event setHandled:YES];
	}
}
// Sent when another listener has handled the event
- (void)activator:(LAActivator *)activator otherListenerDidHandleEvent:(LAEvent *)event {
	// Called when some other listener received an event; we should cleanup
	[self dismiss];
}
// Sent from the settings pane when a listener is assigned
- (void)activator:(LAActivator *)activator receivePreviewEventForListenerName:(NSString *)listenerName {
	//実行
		// int returnCode = system("/usr/bin/open com.mycompany.MyAppName");
		
}

// Metadata (may be cached)
// Listener name
- (NSString *)activator:(LAActivator *)activator requiresLocalizedTitleForListenerName:(NSString *)listenerName {
	return @"FreezaFreezer";
}
// Listener description
- (NSString *)activator:(LAActivator *)activator requiresLocalizedDescriptionForListenerName:(NSString *)listenerName {
	return @"Freeze your foreground application.";
}
// Group name
- (NSString *)activator:(LAActivator *)activator requiresLocalizedGroupForListenerName:(NSString *)listenerName {
	return @"FreezaListeners";
}
// Prevent unassignment when trying to unassign the last event
- (NSNumber *)activator:(LAActivator *)activator requiresRequiresAssignmentForListenerName:(NSString *)listenerName {
	// Return YES if you need at least one assignment
	return [NSNumber numberWithBool:NO];
}
// Compatible event modes
- (NSArray *)activator:(LAActivator *)activator requiresCompatibleEventModesForListenerWithName:(NSString *)listenerName {
	return [NSArray arrayWithObjects:@"application", nil];
}
// Compatibility with events
- (NSNumber *)activator:(LAActivator *)activator requiresIsCompatibleWithEventName:(NSString *)eventName listenerName:(NSString *)listenerName {
	return [NSNumber numberWithBool:YES];
}
// Group assignment filtering
- (NSArray *)activator:(LAActivator *)activator requiresExclusiveAssignmentGroupsForListenerName:(NSString *)listenerName {
	return [NSArray array];
}
// Key querying
- (id)activator:(LAActivator *)activator requiresInfoDictionaryValueOfKey:(NSString *)key forListenerWithName:(NSString *)listenerName {
	// HBLogDebug(@"requiresInfoDictionaryValueOfKey: %@", key);
	return nil;
}
// Powered display
- (BOOL)activator:(LAActivator *)activator requiresNeedsPoweredDisplayForListenerName:(NSString *)listenerName {
	// Called when the listener is incompatible with the lockscreen event mode
	// Return YES if you need the display to be powered
	return YES;
}

// Icons

//  Fast path that supports scale
- (NSData *)activator:(LAActivator *)activator requiresIconDataForListenerName:(NSString *)listenerName scale:(CGFloat *)scale {
	return nil;
}
- (NSData *)activator:(LAActivator *)activator requiresSmallIconDataForListenerName:(NSString *)listenerName scale:(CGFloat *)scale {
	return nil;
}
//  Legacy
- (NSData *)activator:(LAActivator *)activator requiresIconDataForListenerName:(NSString *)listenerName {
	return nil;
}
- (NSData *)activator:(LAActivator *)activator requiresSmallIconDataForListenerName:(NSString *)listenerName {
	return nil;
}
//  For cases where PNG data isn't available quickly
- (UIImage *)activator:(LAActivator *)activator requiresIconForListenerName:(NSString *)listenerName scale:(CGFloat)scale {
	return nil;
}
- (UIImage *)activator:(LAActivator *)activator requiresSmallIconForListenerName:(NSString *)listenerName scale:(CGFloat)scale {
	return nil;
}
// Glyph
- (id)activator:(LAActivator *)activator requiresGlyphImageDescriptorForListenerName:(NSString *)listenerName {
	return nil;
}

// Removal (useful for dynamic listeners)

- (BOOL)activator:(LAActivator *)activator requiresSupportsRemovalForListenerWithName:(NSString *)listenerName {
	// if YES, activator:requestsRemovalForListenerWithName: will be called
	return NO;
}
- (void)activator:(LAActivator *)activator requestsRemovalForListenerWithName:(NSString *)listenerName {
	// Get rid of the listener object
	return;
}

// Configuration view controller

- (NSString *)activator:(LAActivator *)activator requiresConfigurationViewControllerClassNameForListenerWithName:(NSString *)listenerName bundle:(NSBundle **)outBundle {
	*outBundle = [NSBundle bundleWithPath:@"/this/should/not/exist.bundle"];
	return nil;
}
- (id)activator:(LAActivator *)activator requestsConfigurationForListenerWithName:(NSString *)listenerName {
	return nil;
}
- (void)activator:(LAActivator *)activator didSaveNewConfiguration:(id)configuration forListenerWithName:(NSString *)listenerName {
	return;
}

@end
