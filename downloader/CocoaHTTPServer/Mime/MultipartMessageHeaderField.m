
#import "MultipartMessageHeaderField.h"
#import "HTTPLogging.h"

#pragma mark log level

#ifdef DEBUG
static const int httpLogLevel = HTTP_LOG_LEVEL_WARN;
#else
static const int httpLogLevel = HTTP_LOG_LEVEL_WARN;
#endif


// helpers
int findChar(const char* str,NSUInteger length, char c);
NSString* extractParamValue(const char* bytes, NSUInteger length, NSStringEncoding encoding);

@interface MultipartMessageHeaderField ()
- (BOOL)parseHeaderValueBytes:(char*)bytes length:(NSUInteger)length encoding:(NSStringEncoding)encoding;
@end

@implementation MultipartMessageHeaderField

- (instancetype)initWithData:(NSData *)data contentEncoding:(NSStringEncoding)encoding {
    
    self = [super init];
    
    if (self) {
        _params = [NSMutableDictionary dictionaryWithCapacity:1];
        
        char* bytes = (char*)data.bytes;
        NSUInteger length = data.length;
        
        int separatorOffset = findChar(bytes, length, ':');
        if (separatorOffset == -1 || separatorOffset >= length-2) {
            HTTPLogError(@"MultipartFormDataParser: Bad format.No colon in field header.");
            // tear down
            return nil;
        }
        
        // header name is always ascii encoded;
        _name = [[NSString alloc]initWithBytes:bytes length:separatorOffset encoding:NSASCIIStringEncoding];
        if (_name == nil) {
            HTTPLogError(@"MultipartFormDataParser: Bad MIME header name.");
            // tear down
            return nil;
        }
        
        // skip the separator and the next ' ' symbol
        bytes += separatorOffset + 2;
        length -= separatorOffset + 2;
        
        separatorOffset = findChar(bytes, length, ';');
        if (separatorOffset == -1) {
            // couldn't find ';', means we don't have extra params here.
            _value = [[NSString alloc]initWithBytes:bytes length:length encoding:encoding];
            
            if (_value == nil) {
                HTTPLogError(@"MultipartFormDataParser: Bad MIME header value for header name: '%@'",_name);
                // tear down
                return nil;
            }
            return self;
        }
        
        _value = [[NSString alloc]initWithBytes:bytes length:separatorOffset encoding:encoding];
        HTTPLogVerbose(@"MultipartFormDataParser: Processing  header field '%@' : '%@'",_name,_value);
        // skipe the separator and the next ' ' symbol
        bytes += separatorOffset + 2;
        length -= separatorOffset + 2;
        
        // parse the "params" part of the header
        if (![self parseHeaderValueBytes:bytes length:length encoding:encoding]) {
            NSString* paramsStr = [[NSString alloc]initWithBytes:bytes length:length encoding:NSASCIIStringEncoding];
            HTTPLogError(@"MultipartFormDataParser: Bad params for header with name '%@' and value '%@'",_name,_value);
            HTTPLogError(@"MultipartFormDataParser: Params str: %@",paramsStr);
            return nil;		
        }
    }
	return self;
}

- (BOOL)parseHeaderValueBytes:(char*)bytes length:(NSUInteger)length encoding:(NSStringEncoding)encoding {
	int offset = 0;
	NSString* currentParam = nil;
	BOOL insideQuote = NO;
	while (offset < length) {
		if( bytes[offset] == '\"' ) {
			if( !offset || bytes[offset-1] != '\\' ) {
			   insideQuote = !insideQuote;
			}
		}

		// skip quoted symbols
		if( insideQuote ) {
			++ offset;
			continue; 
		}
		if (bytes[offset] == '=') {
			if(currentParam) {
				// found '=' before terminating previous param.
				return NO;
			}
			currentParam = [[NSString alloc]initWithBytes:bytes length:offset encoding:NSASCIIStringEncoding];

			bytes+=offset + 1;
			length -= offset + 1;
			offset = 0;
			continue;
		}
        
		if (bytes[offset] == ';') {
			if(!currentParam) {
				// found ; before stating '='.
				HTTPLogError(@"MultipartFormDataParser: Unexpected ';' when parsing header");
				return NO;
			}
			NSString* paramValue = extractParamValue(bytes, offset,encoding);
            
            if (paramValue == nil) {
				HTTPLogWarn(@"MultipartFormDataParser: Failed to exctract paramValue for key %@ in header %@",currentParam,_name);
			} else {
#ifdef DEBUG
				if (_params[currentParam]) {
					HTTPLogWarn(@"MultipartFormDataParser: param %@ mentioned more then once in header %@",currentParam,_name);
				}
#endif
                _params[currentParam] = paramValue;
				HTTPLogVerbose(@"MultipartFormDataParser: header param: %@ = %@",currentParam,paramValue);
			}

			currentParam = nil;

			// ';' separator has ' ' following, skip them.
			bytes+=offset + 2;
			length -= offset + 2;
			offset = 0;
		}
		++ offset;
	}

	// add last param
	if (insideQuote) {
		HTTPLogWarn(@"MultipartFormDataParser: unterminated quote in header %@",_name);
	}
    
	if (currentParam) {
		NSString *paramValue = extractParamValue(bytes, length, encoding);

		if( nil == paramValue ) {
			HTTPLogError(@"MultipartFormDataParser: Failed to exctract paramValue for key %@ in header %@",currentParam,_name);
		}

#ifdef DEBUG
		if (_params[currentParam]) {
			HTTPLogWarn(@"MultipartFormDataParser: param %@ mentioned more then once in one header",currentParam);
		}
#endif
        _params[currentParam] = paramValue;
		HTTPLogVerbose(@"MultipartFormDataParser: header param: %@ = %@",currentParam,paramValue);
		currentParam = nil;
	}
	
	return YES;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"%@:%@\n params: %@",_name,_value,_params];
}

@end

int findChar(const char* str, NSUInteger length, char c) {
	int ret = -1;
    for (int offset = 0; offset < length; offset++) {
        if (str[offset] == c) {
            ret = offset;
            break;
        }
    }
	return ret;
}

NSString *extractParamValue(const char* bytes, NSUInteger length, NSStringEncoding encoding) {
	if (!length) {
        return nil;
    }
		
	NSMutableString *value = nil;
	
	if (bytes[0] == '"') {
		// values may be quoted. Strip the quotes to get what we need.
		value = [[NSMutableString alloc] initWithBytes:bytes + 1 length: length - 2 encoding:encoding]; 
	} else {
		value = [[NSMutableString alloc] initWithBytes:bytes length: length encoding:encoding];
	}
    
	// restore escaped symbols
	NSRange range= [value rangeOfString:@"\\"];
	while (range.length) {
		[value deleteCharactersInRange:range];
		range.location ++;
		range = [value rangeOfString:@"\\" options:NSLiteralSearch range: range];
	}
    
	return value;
}

