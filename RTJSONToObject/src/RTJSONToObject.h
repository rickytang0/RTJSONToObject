//
//  RTJSONToObject.h
//  RTJSONToObject
//
//  Created by rickytang on 13-10-11.
//  Copyright (c) 2013年 Ricky Tang. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    kClassTypeNull,
    kClassTypeNumber,
    kClassTypeString,
    kClassTypeArray,
    kClassTypeDictionary,
    kClassTypeObject,
    kClassTypeNone,
}kClassType;

typedef id (^RTJSONToObjectBlock)(id data);

typedef NSDate* (^RTJSONToObjectDateBlock)(id data,id key);

typedef NSString* (^RTJSONToObjectStringBlock)(id data);

typedef NSString* (^RTJSONToObjectStringChangeBlock)(id data,id key);

typedef NSNumber* (^RTJSONToObjectNumberBlock)(id data,id key);

@interface RTJSONToObject : NSObject
{
    RTJSONToObjectDateBlock _RTJSONToObjectDateConvertBlock;
    
    RTJSONToObjectStringBlock _RTJSONToObjectStringConvertEncodingBlock;
    
    RTJSONToObjectStringChangeBlock _RTJSONToObjectStringChangeBlock;
    
    RTJSONToObjectNumberBlock _RTJSONToObjectNumberConvertBlock;
}


//Converter
-(void)setDateConvertBlock:(RTJSONToObjectDateBlock)aDataConvertBlock;

-(void)setStringConvertEncodingBlock:(RTJSONToObjectStringBlock)aStringConvertBlock;

-(void)setStringChangeBlock:(RTJSONToObjectStringChangeBlock)aStringChangeBlock;

-(void)setNumberConvertBlock:(RTJSONToObjectNumberBlock)aNumberConvertBlock;



/*
 set the bean from every object
 */

-(id)setObjectWithClass:(Class)_class jsonString:(NSString *)_jsonString;

-(id)setObjectWithClass:(Class)_class jsonData:(NSData *)_data;

-(NSArray *)setObjectWithClass:(Class)_class array:(NSArray *)_array;

-(id)setObjectWithObject:(id)_object fromDictionary:(NSDictionary *)dic;


/*
 set the bean to every object
 */
-(NSMutableDictionary *)convertToDictionaryFromObject:(id)_object;

-(NSData *)convertToJSONFromObject:(id)_object;



/*
 异步处理
 */

-(void)setObjectAsynWithClass:(Class)_class jsonString:(NSString *)_jsonString sucess:(void(^)(id object))sucess fail:(void(^)(void))fail;

-(void)setObjectAsynWithClass:(Class)_class jsonData:(NSData *)_data sucess:(void (^)(id object))sucess fail:(void (^)(void))fail;

-(void)setObjectAsynWithClass:(Class)_class array:(NSArray *)_array sucess:(void (^)(NSArray *array))sucess fail:(void (^)(void))fail;

-(void)setObjectAsynWithbject:(id)_object fromDictionary:(NSDictionary *)dic sucess:(void (^)(id object))sucess fail:(void (^)(void))fail;

-(void)AsynConvertToDictionaryFromObject:(id)_object sucess:(void(^)(NSDictionary *dic))sucess fail:(void(^)(void))fail;

-(void)AsynConvertToJSONFromObject:(id)_objct sucess:(void(^)(NSData *jsonData))sucess fail:(void(^)(void))fail;
@end
