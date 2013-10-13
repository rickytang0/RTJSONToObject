//
//  RTJSONToObject.m
//  RTJSONToObject
//
//  Created by rickytang on 13-10-11.
//  Copyright (c) 2013年 Ricky Tang. All rights reserved.
//

#import "RTJSONToObject.h"
#import <objc/runtime.h>



@interface RTJSONToObject ()
-(void)setupDefualtConvertBlock;

-(kClassType)getClassTypeWithObject:(id)object;

-(SEL)getSeletorWith:(NSString *)_key;

-(id)setObjectWith:(id)_object andValue:(NSObject *)_value andKey:(NSString *)_key;
@end

@implementation RTJSONToObject


-(id)init
{
    if (self = [super init]) {
        [self setupDefualtConvertBlock];
    }
    return self;
}

-(void)dealloc
{
    _RTJSONToObjectDateConvertBlock = nil;
    _RTJSONToObjectStringConvertEncodingBlock = nil;
    _RTJSONToObjectStringChangeBlock = nil;
    _RTJSONToObjectNumberConvertBlock = nil;
}

-(void)setupDefualtConvertBlock
{
    //设置默认时间转换器
    [self setDateConvertBlock:^NSDate* (id data,id key){
        
        if (!data) {
            return nil;
        }
        
        if (![data isKindOfClass:[NSString class]]) {
            return nil;
        }
        
        NSString *dateString = (NSString *)data;
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        [formatter setTimeZone:[NSTimeZone systemTimeZone]];
        NSDate *date1 = [formatter dateFromString: dateString];
        return date1;
    }];
    
}


-(void)setDateConvertBlock:(RTJSONToObjectDateBlock)aDataConvertBlock
{
    _RTJSONToObjectDateConvertBlock = nil;
    _RTJSONToObjectDateConvertBlock = [aDataConvertBlock copy];
}

-(void)setStringConvertEncodingBlock:(RTJSONToObjectStringBlock)aStringConvertBlock
{
    _RTJSONToObjectStringConvertEncodingBlock = nil;
    _RTJSONToObjectStringConvertEncodingBlock = [aStringConvertBlock copy];
}

-(void)setNumberConvertBlock:(RTJSONToObjectNumberBlock)aNumberConvertBlock
{
    _RTJSONToObjectNumberConvertBlock = nil;
    _RTJSONToObjectNumberConvertBlock = [aNumberConvertBlock copy];
}


-(void)setStringChangeBlock:(RTJSONToObjectStringChangeBlock)aStringChangeBlock
{
    _RTJSONToObjectStringChangeBlock = nil;
    _RTJSONToObjectStringChangeBlock = [aStringChangeBlock copy];
}

- (SEL)getSeletorWith:(NSString *)_key
{
    NSString *keyTemp = [_key copy];
    NSString *firstChar = [keyTemp substringWithRange:NSMakeRange(0, 1)];
    firstChar = [firstChar uppercaseString];
    keyTemp = [keyTemp stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:firstChar];
    
    NSString *selectorString = [NSString stringWithFormat:@"set%@:",keyTemp];
    NSLog(@"%@",selectorString);
    
    SEL seletor = NSSelectorFromString(selectorString);
    return seletor;
}


-(kClassType)getClassTypeWithObject:(id)object
{
    if (!object || (NSNull *)object == [NSNull null]) {
        return kClassTypeNull;
    }
    else if ([object isKindOfClass:[NSString class]])
    {
        return kClassTypeString;
    }
    else if ([object isKindOfClass:[NSNumber class]])
    {
        return kClassTypeNumber;
    }
    else if ([object isKindOfClass:[NSArray class]])
    {
        return kClassTypeArray;
    }
    else if ([object isKindOfClass:[NSDictionary class]])
    {
        return kClassTypeDictionary;
    }
    else if([object isMemberOfClass:[NSObject class]] && ![object isKindOfClass:[NSString class]] && ![object isKindOfClass:[NSNumber class]] && ![object isKindOfClass:[NSArray class]] && ![object isKindOfClass:[NSDictionary class]]){
        return kClassTypeObject;
    }
    else{
        return kClassTypeNone;
    }
}


-(id)setObjectWith:(id)_object andValue:(NSObject *)_value andKey:(NSString *)_key
{
    SEL seletor;
    seletor = [self getSeletorWith:_key];
    
    
    //无此方法就不执行
    if (![_object respondsToSelector:seletor]) {
        return nil;
    }
    
    kClassType type = [self getClassTypeWithObject:_value];
    switch (type) {
        case kClassTypeNull:
            return nil;
            break;
        case kClassTypeString:
        {
            NSDate *date = (NSDate *)_RTJSONToObjectDateConvertBlock(_value,_key);
            if (date) {
                [_object setValue:date forKey:_key];
                
            }
            _value = (_RTJSONToObjectStringChangeBlock) ? _RTJSONToObjectStringChangeBlock(_value,_key) : _value;
            [_object setValue:_value forKey:_key];
        }
            break;
        case kClassTypeNumber:
        {
            if ([_object isKindOfClass:[NSNumber class]]) {
                _object = (_RTJSONToObjectNumberConvertBlock) ? _RTJSONToObjectNumberConvertBlock(_value,_key) : _object;
            }
        }
        case kClassTypeDictionary:
        case kClassTypeArray:
            [_object setValue:_value forKey:_key];
            break;
        case kClassTypeNone:
            return nil;
        default:
            break;
    }
    return _object;
}


-(id)setObjectWithClass:(Class)_class jsonString:(NSString *)_jsonString
{
    NSData *data = [_jsonString dataUsingEncoding:NSUTF8StringEncoding];
    return [self setObjectWithClass:_class jsonData:data];
}

-(id)setObjectWithClass:(Class)_class jsonData:(NSData *)_data
{
    NSError *error = nil;
    id temp = [NSJSONSerialization JSONObjectWithData:_data options:NSJSONReadingMutableContainers error:&error];
    
    NSAssert(!error, @"JSONSerialization can not parse");
    
    if ([temp isKindOfClass:[NSArray class]]) {
        return [self setObjectWithClass:_class array:temp];
    }
    else{
        return [self setObjectWithObject:[_class new] fromDictionary:temp];
    }
}

-(id)setObjectWithObject:(id)_object fromDictionary:(NSDictionary *)dic
{
    __block id temp;
    [dic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
        //if can not find model value and the obj is array then goto parse array
        if ([obj isKindOfClass:[NSArray class]]) {
            temp = [self setObjectWithClass:[_object class] array:obj];
        }
        else{
            temp = [self setObjectWith:_object andValue:obj andKey:key];
        }
    }];
    return temp;
}


-(NSArray *)setObjectWithClass:(Class)_class array:(NSArray *)_array
{
    NSMutableArray *temp = [[NSMutableArray alloc] initWithCapacity:_array.count];
    [_array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
        if ([obj isKindOfClass:[NSDictionary class]]) {
            id tempObject = [self setObjectWithObject:[_class new] fromDictionary:obj];
            if (tempObject) {
                [temp addObject:tempObject];
            }
        }
        else if([obj isKindOfClass:[NSArray class]]){
            [temp arrayByAddingObjectsFromArray:[self setObjectWithClass:_class array:obj]];
        }
    }];
    return temp;
}


-(NSMutableDictionary *)convertToDictionaryFromObject:(id)_object
{
    Class clazz = [_object class];
    u_int count;
    
    
    //得到所有property的名,get the class's properties name
    objc_property_t* properties = class_copyPropertyList(clazz, &count);
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] initWithCapacity:count];
    for (int i = 0; i < count ; i++)
    {
        const char* propertyName = property_getName(properties[i]);
        
        NSString *proString = [NSString stringWithCString:propertyName encoding:NSUTF8StringEncoding];
        SEL seletor = [self getSeletorWith:proString];
        if ([_object respondsToSelector:seletor]) {
            
            id temp = [_object valueForKey:proString];
            
            [dic setObject:temp forKey:proString];
            
        }
    }
    free(properties);
    
    return dic;
}

-(NSData *)convertToJSONFromObject:(id)_object
{
    NSDictionary *dic = [self convertToDictionaryFromObject:_object];
    
    NSError *error = nil;
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
    
    NSAssert(!error, @"JSONSerialization can not write");
    
    return data;
}



-(void)setObjectAsynWithClass:(Class)_class jsonString:(NSString *)_jsonString sucess:(void(^)(id object))sucess fail:(void(^)(void))fail
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        id temp = [self setObjectWithClass:_class jsonString:_jsonString];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            if (temp) {
                sucess(temp);
            }
            else
            {
                fail();
            }
        });
    });
}


-(void)setObjectAsynWithClass:(Class)_class jsonData:(NSData *)_data sucess:(void (^)(id))sucess fail:(void (^)(void))fail
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        id temp = [self setObjectWithClass:_class jsonData:_data];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            if (temp) {
                sucess(temp);
            }
            else
            {
                fail();
            }
        });
    });
}


-(void)setObjectAsynWithClass:(Class)_class array:(NSArray *)_array sucess:(void (^)(NSArray *array))sucess fail:(void (^)(void))fail
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        id temp = [self setObjectWithClass:_class array:_array];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            if (temp) {
                sucess(temp);
            }
            else
            {
                fail();
            }
        });
    });
}


-(void)setObjectAsynWithbject:(id)_object fromDictionary:(NSDictionary *)dic sucess:(void (^)(id object))sucess fail:(void (^)(void))fail
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        id temp = [self setObjectWithObject:_object fromDictionary:dic];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            if (temp) {
                sucess(temp);
            }
            else
            {
                fail();
            }
        });
    });
}


-(void)AsynConvertToDictionaryFromObject:(id)_object sucess:(void(^)(NSDictionary *dic))sucess fail:(void(^)(void))fail
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        id temp = [self convertToDictionaryFromObject:_object];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            if (temp) {
                sucess(temp);
            }
            else
            {
                fail();
            }
        });
    });
}

-(void)AsynConvertToJSONFromObject:(id)_objct sucess:(void(^)(NSData *jsonData))sucess fail:(void(^)(void))fail
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        id temp = [self convertToJSONFromObject:_objct];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            if (temp) {
                sucess(temp);
            }
            else
            {
                fail();
            }
        });
    });
}




@end
