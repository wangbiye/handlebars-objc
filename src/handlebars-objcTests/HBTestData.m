//
//  HBTestData.m
//  handlebars-objc
//
//  Created by Bertrand Guiheneuf on 3/25/14.
//  Copyright (c) 2014 Fotonauts. All rights reserved.
//


#import "HBTestCase.h"
#import "HBHandlebars.h"
#import <Foundation/Foundation.h>

#define YHLog(format, ...) printf("Class: <%s:(%d)>\nMethod: %s \n%s\n", [[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, __PRETTY_FUNCTION__, [[NSString stringWithFormat:(format), ##__VA_ARGS__] UTF8String] )


@interface HBTestData : HBTestCase

@end

@implementation HBTestData

- (HBHelperBlock) letHelper
{
    return ^(HBHelperCallingInfo* callingInfo) {
        
        HBDataContext* currentDataContext = callingInfo.data;
        HBDataContext* descendantDataContext = currentDataContext ? [currentDataContext copy] : [HBDataContext new];
        
        for (NSString* paramName in callingInfo.namedParameters) {
            descendantDataContext[paramName] = callingInfo.namedParameters[paramName];
        }
        
        return callingInfo.statements(callingInfo.context, descendantDataContext);
    };
}

- (HBHelperBlock)iffHelper {
    __weak __typeof__(self) weakSelf = self;
    return [^(HBHelperCallingInfo *callingInfo) {
        HBDataContext *currentDataContext = callingInfo.data;
        HBDataContext *descendantDataContext = currentDataContext ? [currentDataContext copy] : [HBDataContext new];
        // 获取传入的条件表达式
        NSString *condition = callingInfo.positionalParameters.firstObject;
        BOOL result = [weakSelf compareConditionString:condition hash:[currentDataContext dataForKey:@"root"]];
        // 将 BOOL 类型的结果转换为字符串
        NSString *resultString = result ? @"true" : @"false";
        
        // 返回处理结果
        return resultString;
    } copy];
}

- (HBHelperBlock) helloHelper
{
    return ^(HBHelperCallingInfo* callingInfo) {
        return [NSString stringWithFormat:@"Hello %@", callingInfo[@"noun"]];
    };
}

- (void) testDeepAtFooTriggersAutomaticTopLevelData
{
    NSError* error = nil;
    id string = @"{{#let world='world'}}{{#if foo}}{{#if foo}}Hello {{@world}}{{/if}}{{/if}}{{/let}}";
    id hash = @{ @"foo" : @true };
    NSDictionary* helpers = @{ @"let" : [self letHelper]};
    
    NSString* result = [self renderTemplate:string withContext:hash withHelpers:helpers error:&error];
    XCTAssert(!error, @"evaluation should not generate an error");
    XCTAssertEqualObjects(result, @"Hello world");
}

- (void) testDataIsInheritedDownstream
{
    NSError* error = nil;
    id string = @"{{#let foo=1 bar=2}}{{#let foo=bar.baz}}{{@bar}}{{@foo}}{{/let}}{{@foo}}{{/let}}";
    id hash = @{ @"bar": @{ @"baz": @"hello world" } };
    NSDictionary* helpers = @{ @"let" : [self letHelper]};
    
    NSString* result = [self renderTemplate:string withContext:hash withHelpers:helpers error:&error];
    YHLog(@"最终结果:\n%@", result);
    XCTAssert(!error, @"evaluation should not generate an error");
    XCTAssertEqualObjects(result, @"2hello world1");
}

- (void) testTheRootContextCanBeLookedUpViaAtRoot
{
    NSError* error = nil;
    id string = @"{{@root.foo}}";
    id hash = @{ @"foo" : @"hello" };
    NSDictionary* helpers = @{ @"let" : [self letHelper]};
    
    NSString* result = [self renderTemplate:string withContext:hash withHelpers:helpers error:&error];
    YHLog(@"最终结果:\n%@", result);
    XCTAssert(!error, @"evaluation should not generate an error");
    XCTAssertEqualObjects(result, @"hello");
}

- (void) testDataContextCanBeClimbedUp
{
    NSError* error = nil;
    id string = @"{{#let foo=1}}{{#let foo=2}}{{#let foo=3}} {{ @foo }} {{ @./foo }} {{ @../foo }} {{ @../../foo }} {{/let}}{{/let}}{{/let}}";
    id hash = @{};
    NSDictionary *helpers = @{ @"let" : [self letHelper]};
    
    NSString *result = [self renderTemplate:string withContext:hash withHelpers:helpers error:&error];
    NSLog(@"%@", result);
    XCTAssert(!error, @"evaluation should not generate an error");
    XCTAssertEqualObjects(result, @" 3 3 2 1 ");
}

- (void)testYHData {
    NSError *renderError = nil;
    NSString *renderTemplate = nil;
    NSString *filePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"template" ofType:@"json"];
    NSData *jsonData = [NSData dataWithContentsOfFile:filePath];
    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];

    if (error) {
        NSLog(@"读取模板数据出错: %@", error.localizedDescription);
        return;
    } else {
        renderTemplate = json[@"template"];
//        NSLog(@"模板数据: %@", renderTemplate);
    }

    filePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"data" ofType:@"json"];
    jsonData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&error];

    id hash = @{};
    if (jsonData) {
        hash = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
        if (hash) {
            // 在这里可以使用读取到的字典数据进行后续操作
//            NSLog(@"读取到的业务数据: %@", helpers);
        } else {
            NSLog(@"读取业务数据出错: %@", error);
            return;
        }
    } else {
        NSLog(@"读取业务数据出错: %@", error);
        return;
    }

    NSDictionary *helpers = @{ @"iff" : [self iffHelper]};
    
    NSString *result = [self renderTemplate:renderTemplate withContext:hash withHelpers:helpers error:&renderError];
    YHLog(@"最终结果:\n%@", result);
    XCTAssert(!error, @"evaluation should not generate an error");
}

- (void)testIf {
    NSError *error;
    NSString *filePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"data" ofType:@"json"];
    NSData *jsonData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&error];
    NSDictionary *hash = @{};
    if (jsonData) {
        hash = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
        if (hash) {
            // 在这里可以使用读取到的字典数据进行后续操作
//            NSLog(@"读取到的业务数据: %@", helpers);
            hash = @{@"isPrintCount": @(true)};
            if (YES) {
                NSLog(@"printCount存在且大于1");
            } else {
                NSLog(@"printCount不存在或者小于等于1");
            }
        } else {
            NSLog(@"读取业务数据出错: %@", error);
            return;
        }
    } else {
        NSLog(@"读取业务数据出错: %@", error);
        return;
    }
}

- (void)testPredicate {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"totalDisc>0"];
    BOOL result = [predicate evaluateWithObject:@{@"totalDisc": @"7"}];
    if (result) {
        NSLog(@"符合条件");
    } else {
        NSLog(@"不符合条件");
    }
}

- (void)testConver {
    NSError *error;
    NSString *filePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"data" ofType:@"json"];
    NSData *jsonData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&error];
    NSDictionary *hash = @{};
    if (jsonData) {
        hash = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
        if (hash) {

        } else {
            NSLog(@"读取业务数据出错: %@", error);
            return;
        }
    } else {
        NSLog(@"读取业务数据出错: %@", error);
        return;
    }
    NSArray *listOfExpressions = @[
        @"true",
        @"false",
        @"shopConf.titleImg",
        @"printCount&&printCount>1",
        @"shopConf.receipt_sx_pricemode == '1'",
        @"shopConf.receipt_sx_pricemode != '1'&&shopConf.receipt_sx_pricemode != '2'",
        @"totalDisc&&totalDisc>0",
        @"priceDiscountAmount&&priceDiscountAmount>0",
        @"promotionDiscountAmount&&promotionDiscountAmount>0",
        @"otherCouponDiscount&&otherCouponDiscount>0",
        @"memberDiscountAmount&&memberDiscountAmount>0",
        @"appMemberExclusiveCouponDiscount&&appMemberExclusiveCouponDiscount>0",
        @"appMemberRandomReductionDiscount&&appMemberRandomReductionDiscount>0",
        @"otherDiscount&&otherDiscount>0",
        @"customerPhone",
        @"hasCouponInfo&&hasCouponInfo.isExistElectronicsCouponse",
        @"memberCredit&&memberCredit>0&&orderCredit&&orderCredit>0&&memberCredit>orderCredit",
        @"titokCouponTotalParValue&&titokCouponTotalParValue>0",
        @"titokCouponTotalSurplusAmount&&titokCouponTotalSurplusAmount>0",
        @"deliveryCouponDiscount&&deliveryCouponDiscount>0",
        @"couponLatitude=='electronicDelivery.coupon'",
        @"deliveryCouponTotalSurplusAmount&&deliveryCouponTotalSurplusAmount>0",
        @"change&&change>0",
        @"payDiscountAmount&&payDiscountAmount>0",
        @"cardBalance&&(cardBalance>0||(cardBalance>=0&&(payCode=='pay.yhcard.micropay'||payCode=='0301'||payCode=='pay.yufu.fucard.entitycard')))",
        @"cardNo",
        @"payCode=='pay.yhcard.micropay'||payCode=='0301'||payCode=='0303'||payCode=='0309'||payCode=='0349'||payCode=='pay.yufu.fucard.entitycard'||payCode=='pay.unionpay.entitycard.report'||payCode=='pay.third.party.one.pass.card'||payCode=='pay.entitycard.shangtongka.report'||payCode=='pay.entitycard.city.report'||payCode=='pay.unionpay.sand.report'||payCode=='pay.unionpay.ccb.report'||payCode=='pay.unionpay.icbc.report'||payCode=='pay.unionpay.shcs.report'||payCode=='pay.unionpay.zjjl.report'",
        @"payCode=='0501'||payCode=='0500'||payCode=='0505'||payCode=='pay.cash.coupon'",
        @"transactionNo",
        @"shopConf.is_print_dzfp!='0'",
        @"shopConf.endtext3",
        @"shopConf.endqrcode",
        @"shopConf.endtext4",
        @"shopConf.endqrcode2",
        @"shopConf.endtext1",
        @"isPrintDigitReceipt||isWxPayPrintDigit",
        @"isPrintDigitReceipt"
    ];
    for (NSString *expression in listOfExpressions) {
        BOOL result = [self compareConditionString:expression hash:hash];
        NSLog(@"%@ => %@", expression, @(result));
        if (result) {
            NSLog(@"符合条件");
        } else {
            NSLog(@"不符合条件");
        }
        NSLog(@"================================");
    }

}

- (BOOL)compareConditionString:(NSString *)string hash:(NSDictionary *)hash {
    if ([string isEqualToString:@"true"] || [string isEqualToString:@"false"]) {
        return [string isEqualToString:@"true"];
    }

    NSArray *splitConditionsAndOperators = [self splitConditionsAndOperators:string];
    
    NSMutableArray *convertedConditions = [NSMutableArray array];
    
    for (NSString *condition in splitConditionsAndOperators) {
        if ([condition isEqualToString:@"&&"] || [condition isEqualToString:@"||"] || [condition isEqualToString:@"("] || [condition isEqualToString:@")"]) {
            [convertedConditions addObject:condition];
        } else {
            BOOL convertedCondition = [self compareSingleCondition:condition hash:hash];
            [convertedConditions addObject:@(convertedCondition)];
        }
    }
    
    NSString *result = [convertedConditions componentsJoinedByString:@" "];
    if ([result containsString:@"&&"] || [result containsString:@"||"]) {
        // 含有连接符
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF == 1"];
        BOOL compareResult = [predicate evaluateWithObject:[NSNumber numberWithBool:[result boolValue]]];
        return compareResult;
    } else {
        BOOL boolResult = [result boolValue];
        return boolResult;
    }
    
}

- (NSArray *)splitConditionsAndOperators:(NSString *)string {
    NSMutableArray *splitConditionsAndOperators = [NSMutableArray array];
    NSUInteger lastMatchEnd = 0;
    NSUInteger length = string.length;
    
    for (NSUInteger i = 0; i < length; i++) {
        unichar c = [string characterAtIndex:i];
        if (c == '(') {
            if (i > lastMatchEnd) {
                NSString *condition = [string substringWithRange:NSMakeRange(lastMatchEnd, i - lastMatchEnd)];
                [splitConditionsAndOperators addObject:condition];
            }
            [splitConditionsAndOperators addObject:@"("];
            NSUInteger j = i;
            int count = 0;
            do {
                unichar c2 = [string characterAtIndex:j];
                if (c2 == '(') {
                    count++;
                } else if (c2 == ')') {
                    count--;
                }
                j++;
            } while (count > 0 && j < length);
            NSString *subString = [string substringWithRange:NSMakeRange(i + 1, j - i - 2)];
            [splitConditionsAndOperators addObjectsFromArray:[self splitConditionsAndOperators:subString]];
            [splitConditionsAndOperators addObject:@")"];
            i = j - 1;
            lastMatchEnd = i + 1;
        } else if ((c == '&' || c == '|') && i < length - 1) {
            unichar nextChar = [string characterAtIndex:i + 1];
            if (c == nextChar) {
                if (i > lastMatchEnd) {
                    NSString *condition = [string substringWithRange:NSMakeRange(lastMatchEnd, i - lastMatchEnd)];
                    [splitConditionsAndOperators addObject:condition];
                }
                NSString *operator = [string substringWithRange:NSMakeRange(i, 2)];
                [splitConditionsAndOperators addObject:operator];
                i++;
                lastMatchEnd = i + 1;
            }
        }
    }
    
    if (lastMatchEnd < length) {
        NSString *lastCondition = [string substringFromIndex:lastMatchEnd];
        [splitConditionsAndOperators addObject:lastCondition];
    }
    
    return splitConditionsAndOperators;
}


- (NSArray *)splitStringWithParentheses:(NSString *)string {
    NSString *subString = [string substringWithRange:NSMakeRange(1, string.length - 2)];
    return [self splitConditionsAndOperators:subString];
}

- (BOOL)compareSingleCondition:(NSString *)condition hash:(NSDictionary *)hash {
    NSString *compareCondition = condition;
    
    if ([compareCondition containsString:@"=="] || [compareCondition containsString:@"!="]) {
        NSString *pattern = @"\\s*(\\w+)\\s*([!=]+)\\s*('[^']*'|\"[^\"]*\"|\\w+)";
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
        NSTextCheckingResult *checkingResult = [regex firstMatchInString:compareCondition options:0 range:NSMakeRange(0, compareCondition.length)];

        if (checkingResult.numberOfRanges == 4) {
            NSString *leftString = [compareCondition substringWithRange:[checkingResult rangeAtIndex:1]];
            NSString *operatorString = [compareCondition substringWithRange:[checkingResult rangeAtIndex:2]];
            NSString *rightString = [compareCondition substringWithRange:[checkingResult rangeAtIndex:3]];
            // 去除双引号和单引号
            rightString = [rightString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"'\""]];
            // 从业务数据中取值
            id hashValue = [hash valueForKeyPath:leftString];
            BOOL compareResult = [self isEqualWithJsonValue:hashValue operator:operatorString stringValue:rightString];
            return compareResult;
        }
        NSLog(@"❌表达式拆解错误: %@❌", compareCondition);
        return NO;
    }
    
    if ([compareCondition containsString:@">="] || [compareCondition containsString:@"<="] || [compareCondition containsString:@">"] || [compareCondition containsString:@"<"]) {
        // 做大小比较, 需要根据业务的数据来比较, 为了防止有和字符串比大小的情况, 拆解重新拼装一次
        // 用正则将字符串分割
        NSString *pattern = @"(.*?)([<>]=?)\\s*(.*)";

        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
        NSTextCheckingResult *checkingResult = [regex firstMatchInString:compareCondition options:0 range:NSMakeRange(0, compareCondition.length)];

        if (checkingResult.numberOfRanges == 4) {
            NSString *leftString = [compareCondition substringWithRange:[checkingResult rangeAtIndex:1]];
            NSString *operatorString = [compareCondition substringWithRange:[checkingResult rangeAtIndex:2]];
            NSString *rightString = [compareCondition substringWithRange:[checkingResult rangeAtIndex:3]];
            // 去除双引号和单引号
            rightString = [rightString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"'\""]];

            // 从业务数据中取值
            id hashValue = [hash valueForKeyPath:leftString];
            BOOL isNumber = NO;
            if ([hashValue isKindOfClass:NSString.class]) {
                // 正则判断 hash value 是不是数字
                NSString *numberPattern = @"^-?\\d+(\\.\\d+)?$";
                NSPredicate *numberPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", numberPattern];
                isNumber = [numberPredicate evaluateWithObject:hashValue];
            } else if ([hashValue isKindOfClass:NSNumber.class]) {
                isNumber = YES;
            }
            
            if (isNumber) {
                // 将字符串转换为数值
                double leftOperand = [leftString doubleValue];
                double rightOperand = [rightString doubleValue];

                // 执行比较操作
                BOOL compareResult = NO;
                if ([operatorString isEqualToString:@"<"]) {
                    compareResult = (leftOperand < rightOperand);
                } else if ([operatorString isEqualToString:@"<="]) {
                    compareResult = (leftOperand <= rightOperand);
                } else if ([operatorString isEqualToString:@">"]) {
                    compareResult = (leftOperand > rightOperand);
                } else if ([operatorString isEqualToString:@">="]) {
                    compareResult = (leftOperand >= rightOperand);
                }
                return compareResult;
            } else {
                NSLog(@"❌业务数据中对应的值不是数字类型, 无法对比: %@❌", hashValue);
                return NO;
            }
        }
        // 分割失败
        NSLog(@"❌表达式拆解错误: %@❌", compareCondition);
        return NO;
    }
    
    // 剩下的就是没有包含对比运算符的
    // 取出业务数据的值
    id hashValue = [hash valueForKeyPath:compareCondition];
    // 判断业务数据是不是布尔, 如果是布尔, 还要特殊判断
    if ([hashValue isKindOfClass:[NSNumber class]]) {
        NSNumber *numberValue = (NSNumber *)hashValue;
        if (CFBooleanGetTypeID() == CFGetTypeID((__bridge CFTypeRef)(numberValue))) {
            // 布尔类型
            compareCondition = [NSString stringWithFormat:@"%@ != nil && %@ == true", compareCondition, compareCondition];
        } else {
            // 其他数值类型
            compareCondition = [NSString stringWithFormat:@"%@ != nil", compareCondition];
        }
    } else {
        // 其他类型
        compareCondition = [NSString stringWithFormat:@"%@ != nil", compareCondition];
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat:compareCondition];
    BOOL compareResults = [predicate evaluateWithObject:hash];
    return compareResults;
}

- (BOOL)isEqualWithJsonValue:(id)jsonValue operator:(NSString *)operator stringValue:(NSString *)strValue {
    if (jsonValue == nil || operator == nil || strValue == nil) {
        return NO;
    }

    if ([jsonValue isKindOfClass:[NSNumber class]] && CFGetTypeID((__bridge CFTypeRef)(jsonValue)) == CFBooleanGetTypeID()) {
        NSNumber *number = [NSNumber numberWithBool:[strValue boolValue]];
        if ([operator isEqualToString:@"=="]) {
            return [jsonValue isEqualToNumber:number];
        } else if ([operator isEqualToString:@"!="]) {
            return ![jsonValue isEqualToNumber:number];
        }
    } else if ([jsonValue isKindOfClass:[NSNumber class]]) {
        NSNumber *number = [NSNumber numberWithDouble:[strValue doubleValue]];
        if ([operator isEqualToString:@"=="]) {
            return [jsonValue isEqualToNumber:number];
        } else if ([operator isEqualToString:@"!="]) {
            return ![jsonValue isEqualToNumber:number];
        }
    } else if ([jsonValue isKindOfClass:[NSString class]]) {
        if ([operator isEqualToString:@"=="]) {
            return [jsonValue isEqualToString:strValue];
        } else if ([operator isEqualToString:@"!="]) {
            return ![jsonValue isEqualToString:strValue];
        }
    } else if ([jsonValue isKindOfClass:[NSNull class]]) {
        if ([operator isEqualToString:@"=="]) {
            return [strValue isEqualToString:@"<null>"];
        } else if ([operator isEqualToString:@"!="]) {
            return ![strValue isEqualToString:@"<null>"];
        }
    }

    return NO;
}



@end
