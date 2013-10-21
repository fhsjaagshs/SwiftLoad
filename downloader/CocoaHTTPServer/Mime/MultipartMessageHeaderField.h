
#import <Foundation/Foundation.h>

//-----------------------------------------------------------------
// interface MultipartMessageHeaderField
//-----------------------------------------------------------------

@interface MultipartMessageHeaderField : NSObject

@property (strong, readonly) NSString *value;
@property (strong, readonly) NSMutableDictionary *params;
@property (strong, readonly) NSString *name;

//- (id) initWithLine:(NSString*) line;
//- (id) initWithName:(NSString*) paramName value:(NSString*) paramValue;

- (instancetype)initWithData:(NSData *)data contentEncoding:(NSStringEncoding)encoding;

@end
