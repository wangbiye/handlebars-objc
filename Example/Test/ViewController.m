//
//  ViewController.m
//  Test
//
//  Created by 王碧野 on 2022/9/6.
//

#import "ViewController.h"
#import <HBHandlebars/HBHandlebars.h>
#import <YHFoundation/YHFoundationConstants.h>

@interface ViewController ()



@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    [self testYHData];
}

- (HBHelperBlock)iffHelper {
    __weak __typeof__(self) weakSelf = self;
    return ^(HBHelperCallingInfo *callingInfo) {
        HBDataContext *currentDataContext = callingInfo.data;
        // 获取传入的条件表达式
        NSString *condition = callingInfo.positionalParameters.firstObject;
        BOOL result = [weakSelf compareConditionString:condition hash:[currentDataContext dataForKey:@"root"]];
        NSString *resultString = result ? callingInfo.statements(callingInfo.context, callingInfo.data) : nil;
        
        // 返回处理结果
        return resultString;
    };
}

- (NSString *)renderTemplate:(NSString *)template withContext:(id)context withHelpers:(NSDictionary *)helpers withPartials:(NSDictionary *)partials error:(NSError **)error {
    return [HBHandlebars renderTemplateString:template withContext:context withHelperBlocks:helpers withPartialStrings:partials error:error];
}

- (NSString *)renderTemplate:(NSString *)template withContext:(id)context withHelpers:(NSDictionary *)helpers error:(NSError **)error {
    return [self renderTemplate:template withContext:context withHelpers:helpers withPartials:nil error:error];
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

/// 结合业务数据解析字符串, 得到最终的布尔值
/// - Parameters:
///   - string: 字符串表达式
///   - hash: 业务数据
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
    
    NSString *expression = [convertedConditions componentsJoinedByString:@""];
    NSLog(@"待解析表达式: %@", expression);
    BOOL boolResult = [self evaluateExpression:expression];
    return boolResult;
}

/// 分割拆解字符串表达式
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

/// 对比运算拆解后的单个小表达式
- (BOOL)compareSingleCondition:(NSString *)condition hash:(NSDictionary *)hash {
    NSString *compareCondition = condition;
    
    if ([compareCondition containsString:@"=="] || [compareCondition containsString:@"!="]) {
        NSString *pattern = @"\\s*([\\w\\.]+)\\s*([!=]{1,2})\\s*('[^']*'|\"[^\"]*\"|\\w+)";
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
            double hashValueNumber = 0;
            if ([hashValue isKindOfClass:NSString.class]) {
                // 正则判断 hash value 是不是数字
                NSString *numberPattern = @"^-?\\d+(\\.\\d+)?$";
                NSPredicate *numberPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", numberPattern];
                BOOL isNumber = [numberPredicate evaluateWithObject:hashValue];
                if (isNumber) {
                    hashValueNumber = [hashValue doubleValue];
                } else {
                    NSLog(@"❌业务数据中对应的值不是数字类型, 无法对比: %@❌", hashValue);
                    return NO;
                }
            } else if ([hashValue isKindOfClass:NSNumber.class]) {
                hashValueNumber = [hashValue doubleValue];
            } else {
                NSLog(@"❌业务数据中对应的值类型异常, 无法对比: %@❌", hashValue);
                return NO;
            }
            
            // 将字符串转换为数值
            double leftOperand = hashValueNumber;
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
    } else if ([hashValue isKindOfClass:NSString.class]) {
        compareCondition = [NSString stringWithFormat:@"%@ != nil && %@ != \"\"", compareCondition, compareCondition];
    } else {
        // 其他类型
        compareCondition = [NSString stringWithFormat:@"%@ != nil", compareCondition];
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat:compareCondition];
    BOOL compareResults = [predicate evaluateWithObject:hash];
    return compareResults;
}

/// 是否相等的表达式对比方法
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

/// 解析最终的布尔表达式, 例如"0&&(0||(0&&(0||0||0)))"
- (BOOL)evaluateExpression:(NSString *)expression {
    // 删除空格
    expression = [expression stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    // 递归处理括号
    NSUInteger leftParanthesisIndex = [expression rangeOfString:@"("].location;
    while (leftParanthesisIndex != NSNotFound) {
        NSUInteger rightParanthesisIndex = [expression rangeOfString:@")"
                                                            options:0
                                                              range:NSMakeRange(leftParanthesisIndex, expression.length - leftParanthesisIndex)].location;
        if (rightParanthesisIndex == NSNotFound) {
            NSLog(@"Error: Invalid expression - %@", expression);
            return NO;
        }
        NSString *innerExpression = [expression substringWithRange:NSMakeRange(leftParanthesisIndex + 1, rightParanthesisIndex - leftParanthesisIndex - 1)];
        BOOL innerResult = [self evaluateExpression:innerExpression];
        expression = [expression stringByReplacingCharactersInRange:NSMakeRange(leftParanthesisIndex, rightParanthesisIndex - leftParanthesisIndex + 1)
                                                         withString:innerResult ? @"1" : @"0"];
        leftParanthesisIndex = [expression rangeOfString:@"("].location;
    }
    
    // 递归处理 "||" 运算符
    NSArray *orComponents = [expression componentsSeparatedByString:@"||"];
    if ([orComponents count] > 1) {
        for (NSString *component in orComponents) {
            if ([self evaluateExpression:component]) return YES;
        }
        return NO;
    }
    
    // 递归处理 "&&" 运算符
    NSArray *andComponents = [expression componentsSeparatedByString:@"&&"];
    if ([andComponents count] > 1) {
        for (NSString *component in andComponents) {
            if (![self evaluateExpression:component]) return NO;
        }
        return YES;
    }
    
    // 检查是否只是简单的 "0" 或 "1"
    if ([expression isEqualToString:@"0"]) return NO;
    if ([expression isEqualToString:@"1"]) return YES;
    
    // 如果不符合以上任何情况，返回错误
    NSLog(@"Error: Invalid expression - %@", expression);
    return NO;
}


@end
