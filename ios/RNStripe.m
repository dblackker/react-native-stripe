#import "RNStripe.h"

@implementation RNStripe
{
    NSString *publishableKey;
    NSString *merchantId;

    BOOL requestIsCompleted;
}

- (instancetype)init {
  if ((self = [super init])) {
    requestIsCompleted = YES;
  }
  return self;
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(init:(NSDictionary *)options) {
    publishableKey = options[@"publishableKey"];
    merchantId = options[@"merchantId"];
    [[STPPaymentConfiguration sharedConfiguration] setPublishableKey:options[@"publishableKey"]];
    [Stripe setDefaultPublishableKey:options[@"publishableKey"]];
}

RCT_EXPORT_METHOD(createTokenWithCard:(NSDictionary *)params
                             resolver:(RCTPromiseResolveBlock)resolve
                             rejecter:(RCTPromiseRejectBlock)reject) {
    if(!requestIsCompleted) {
        NSError *error = [NSError
          errorWithDomain:@"com.reactlibrary.RNStripe"
          code:-2
          userInfo:@{NSLocalizedDescriptionKey: @"Previous request is not completed"}
        ];
        reject([NSString stringWithFormat:@"%ld", error.code], error.localizedDescription, error);
        return;
    }

    requestIsCompleted = NO;
    STPCardParams* card = [self createCardParamFromDictionary:params];

    STPAPIClient *stripeAPIClient = [self createAPIClient];

    [stripeAPIClient createTokenWithCard:card completion:^(STPToken *token, NSError *error) {
        requestIsCompleted = YES;

        if (error) {
            reject(nil, nil, error);
        } else {
            resolve([self convertTokenObject:token]);
        }
    }];
}

RCT_EXPORT_METHOD(createSourceWithCard:(NSDictionary *)params
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    if(!requestIsCompleted) {
        NSError *error = [NSError
                          errorWithDomain:@"com.reactlibrary.RNStripe"
                          code:-2
                          userInfo:@{NSLocalizedDescriptionKey: @"Previous request is not completed"}
                          ];
        reject([NSString stringWithFormat:@"%ld", error.code], error.localizedDescription, error);
        return;
    }
    
    requestIsCompleted = NO;
    STPCardParams* card = [self createCardParamFromDictionary:params];
    STPSourceParams *sourceParams = [STPSourceParams cardParamsWithCard:card];

    STPAPIClient *stripeAPIClient = [self createAPIClient];
    
    [stripeAPIClient createSourceWithParams:sourceParams completion:^(STPSource *source, NSError *error) {
        requestIsCompleted = YES;
        
        if (error) {
            reject(nil, nil, error);
        } else {
            resolve([self convertSourceObject:source]);
        }
    }];
}

- (STPAPIClient *)createAPIClient {
    return [[STPAPIClient alloc] initWithPublishableKey:[Stripe defaultPublishableKey]];
}

- (STPCardParams *)createAddressFromDictionary:(NSDictionary *)params {
    STPAddress *address = [[STPAddress alloc] init];

    [address setName: params[@"name"]];
    [address setLine1: params[@"line1"]];
    [address setLine2: params[@"line2"]];
    [address setCity: params[@"city"]];
    [address setState: params[@"state"]];
    [address setCountry: params[@"country"]];
    [address setPhone: params[@"phone"]];
    [address setEmail: params[@"email"]];
    [address setPostalCode: params[@"postalCode"]];

    return address;
}

- (STPCardParams *)createCardParamFromDictionary:(NSDictionary *)params {
    STPCardParams *card = [[STPCardParams alloc] init];

    [card setNumber: params[@"number"]];
    [card setExpMonth: [params[@"expMonth"] integerValue]];
    [card setExpYear: [params[@"expYear"] integerValue]];
    [card setCvc: params[@"cvc"]];

    [card setName: params[@"name"]];
    [card setCurrency: params[@"currency"]];
    [card setAddress: [self createAddressFromDictionary:params[@"address"]]];

    return card;
}

- (NSDictionary *)convertTokenObject:(STPToken*)token {
    NSMutableDictionary *result = [@{} mutableCopy];

    // Token
    [result setValue:token.tokenId forKey:@"tokenId"];
    [result setValue:@([token.created timeIntervalSince1970]) forKey:@"created"];
    [result setValue:@(token.livemode) forKey:@"livemode"];

    // Card
    if (token.card) {
        NSMutableDictionary *card = [@{} mutableCopy];
        [result setValue:card forKey:@"card"];

        [card setValue:token.card.cardId forKey:@"cardId"];

        [card setValue:token.card.last4 forKey:@"last4"];
        [card setValue:token.card.dynamicLast4 forKey:@"dynamicLast4"];
        [card setValue:@(token.card.isApplePayCard) forKey:@"isApplePayCard"];
        [card setValue:@(token.card.expMonth) forKey:@"expMonth"];
        [card setValue:@(token.card.expYear) forKey:@"expYear"];
        [card setValue:token.card.country forKey:@"country"];
        [card setValue:token.card.currency forKey:@"currency"];

        [card setValue:token.card.name forKey:@"name"];
        [card setValue:token.card.addressLine1 forKey:@"addressLine1"];
        [card setValue:token.card.addressLine2 forKey:@"addressLine2"];
        [card setValue:token.card.addressCity forKey:@"addressCity"];
        [card setValue:token.card.addressState forKey:@"addressState"];
        [card setValue:token.card.addressCountry forKey:@"addressCountry"];
        [card setValue:token.card.addressZip forKey:@"addressZip"];
    }
    return result;
}

- (NSDictionary *)convertSourceObject:(STPSource*)source {
    NSMutableDictionary *result = [@{} mutableCopy];
    
    // Source
    [result setValue:source.stripeID forKey:@"sourceId"];
    [result setValue:source.clientSecret forKey:@"clientSecret"];
    [result setValue:source.amount forKey:@"amount"];
    [result setValue:@([source.created timeIntervalSince1970]) forKey:@"created"];
    [result setValue:source.currency forKey:@"currency"];
    [result setValue:@(source.livemode) forKey:@"livemode"];
    
    
    // Flow
    [result setValue:[self sourceFlow:source.flow] forKey:@"flow"];
    
    // Metadata
    if (source.metadata) {
        [result setValue:source.metadata forKey:@"metadata"];
    }
    
    // Owner
    if (source.owner) {
        NSMutableDictionary *owner = [@{} mutableCopy];
        [result setValue:owner forKey:@"owner"];
        
        if (source.owner.address) {
            [owner setValue:[self address:source.owner.address] forKey:@"address"];
        }
        [owner setValue:source.owner.email forKey:@"email"];
        [owner setValue:source.owner.name forKey:@"name"];
        [owner setValue:source.owner.phone forKey:@"phone"];
        if (source.owner.verifiedAddress) {
            [owner setValue:[self address:source.owner.verifiedAddress] forKey:@"verifiedAddress"];
        }
        [owner setValue:source.owner.verifiedEmail forKey:@"verifiedEmail"];
        [owner setValue:source.owner.verifiedName forKey:@"verifiedName"];
        [owner setValue:source.owner.verifiedPhone forKey:@"verifiedPhone"];
    }
    
    // Details
    if (source.details) {
        [result setValue:source.details forKey:@"details"];
    }
    
    // Receiver
    if (source.receiver) {
        NSMutableDictionary *receiver = [@{} mutableCopy];
        [result setValue:receiver forKey:@"receiver"];
        
        [receiver setValue:source.receiver.address forKey:@"address"];
        [receiver setValue:source.receiver.amountCharged forKey:@"amountCharged"];
        [receiver setValue:source.receiver.amountReceived forKey:@"amountReceived"];
        [receiver setValue:source.receiver.amountReturned forKey:@"amountReturned"];
    }
    
    // Redirect
    if (source.redirect) {
        NSMutableDictionary *redirect = [@{} mutableCopy];
        [result setValue:redirect forKey:@"redirect"];
        NSString *returnURL = source.redirect.returnURL.absoluteString;
        [redirect setValue:returnURL forKey:@"returnURL"];
        NSString *url = source.redirect.url.absoluteString;
        [redirect setValue:url forKey:@"url"];
        [redirect setValue:[self sourceRedirectStatus:source.redirect.status] forKey:@"status"];
    }
    
    // Verification
    if (source.verification) {
        NSMutableDictionary *verification = [@{} mutableCopy];
        [result setValue:verification forKey:@"verification"];
        
        [verification setValue:source.verification.attemptsRemaining forKey:@"attemptsRemaining"];
        [verification setValue:[self sourceVerificationStatus:source.verification.status] forKey:@"status"];
    }
    
    // Status
    [result setValue:[self sourceStatus:source.status] forKey:@"status"];
    
    // Type
    [result setValue:[self sourceType:source.type] forKey:@"type"];
    
    // Usage
    [result setValue:[self sourceUsage:source.usage] forKey:@"usage"];
    
    // CardDetails
    if (source.cardDetails) {
        NSMutableDictionary *cardDetails = [@{} mutableCopy];
        [result setValue:cardDetails forKey:@"cardDetails"];
        
        [cardDetails setValue:source.cardDetails.last4 forKey:@"last4"];
        [cardDetails setValue:@(source.cardDetails.expMonth) forKey:@"expMonth"];
        [cardDetails setValue:@(source.cardDetails.expYear) forKey:@"expYear"];
        [cardDetails setValue:[self cardBrand:source.cardDetails.brand] forKey:@"brand"];
        [cardDetails setValue:[self cardFunding:source.cardDetails.funding] forKey:@"funding"];
        [cardDetails setValue:source.cardDetails.country forKey:@"country"];
        [cardDetails setValue:[self card3DSecureStatus:source.cardDetails.threeDSecure] forKey:@"threeDSecure"];
    }
    
    // SepaDebitDetails
    if (source.sepaDebitDetails) {
        NSMutableDictionary *sepaDebitDetails = [@{} mutableCopy];
        [result setValue:sepaDebitDetails forKey:@"sepaDebitDetails"];
        
        [sepaDebitDetails setValue:source.sepaDebitDetails.last4 forKey:@"last4"];
        [sepaDebitDetails setValue:source.sepaDebitDetails.bankCode forKey:@"bankCode"];
        [sepaDebitDetails setValue:source.sepaDebitDetails.country forKey:@"country"];
        [sepaDebitDetails setValue:source.sepaDebitDetails.fingerprint forKey:@"fingerprint"];
        [sepaDebitDetails setValue:source.sepaDebitDetails.mandateReference forKey:@"mandateReference"];
        NSString *mandateURL = source.sepaDebitDetails.mandateURL.absoluteString;
        [sepaDebitDetails setValue:mandateURL forKey:@"mandateURL"];
    }
    
    return result;
}

- (NSString *)sourceFlow:(STPSourceFlow)inputFlow {
    switch (inputFlow) {
        case STPSourceFlowNone:
            return @"none";
        case STPSourceFlowRedirect:
            return @"redirect";
        case STPSourceFlowCodeVerification:
            return @"codeVerification";
        case STPSourceFlowReceiver:
            return @"receiver";
        case STPSourceFlowUnknown:
        default:
            return @"unknown";
    }
}

- (NSString *)sourceRedirectStatus:(STPSourceRedirectStatus)inputStatus {
    switch (inputStatus) {
        case STPSourceRedirectStatusPending:
            return @"pending";
        case STPSourceRedirectStatusSucceeded:
            return @"succeeded";
        case STPSourceRedirectStatusFailed:
            return @"failed";
        case STPSourceRedirectStatusUnknown:
        default:
            return @"unknown";
    }
}

- (NSString *)sourceVerificationStatus:(STPSourceVerificationStatus)inputStatus {
    switch (inputStatus) {
        case STPSourceVerificationStatusPending:
            return @"pending";
        case STPSourceVerificationStatusSucceeded:
            return @"succeeded";
        case STPSourceVerificationStatusFailed:
            return @"failed";
        case STPSourceVerificationStatusUnknown:
        default:
            return @"unknown";
    }
}

- (NSString *)sourceType:(STPSourceType)inputType {
    switch (inputType) {
        case STPSourceTypeBancontact:
            return @"bancontact";
        case STPSourceTypeBitcoin:
            return @"bitcoin";
        case STPSourceTypeGiropay:
            return @"giropay";
        case STPSourceTypeIDEAL:
            return @"ideal";
        case STPSourceTypeSEPADebit:
            return @"sepaDebit";
        case STPSourceTypeSofort:
            return @"sofort";
        case STPSourceTypeThreeDSecure:
            return @"threeDSecure";
        case STPSourceTypeAlipay:
            return @"alipay";
        case STPSourceTypeUnknown:
        default:
            return @"unknown";
    }
}

- (NSString *)cardBrand:(STPCardBrand)inputBrand {
    switch (inputBrand) {
        case STPCardBrandJCB:
            return @"JCB";
        case STPCardBrandAmex:
            return @"American Express";
        case STPCardBrandVisa:
            return @"Visa";
        case STPCardBrandDiscover:
            return @"Discover";
        case STPCardBrandDinersClub:
            return @"Diners Club";
        case STPCardBrandMasterCard:
            return @"MasterCard";
        case STPCardBrandUnknown:
        default:
            return @"Unknown";
    }
}

- (NSString *)cardFunding:(STPCardFundingType)inputFunding {
    switch (inputFunding) {
        case STPCardFundingTypeDebit:
            return @"debit";
        case STPCardFundingTypeCredit:
            return @"credit";
        case STPCardFundingTypePrepaid:
            return @"prepaid";
        case STPCardFundingTypeOther:
        default:
            return @"unknown";
    }
}

- (NSString *)card3DSecureStatus:(STPSourceCard3DSecureStatus)inputStatus {
    switch (inputStatus) {
        case STPSourceCard3DSecureStatusRequired:
            return @"required";
        case STPSourceCard3DSecureStatusOptional:
            return @"optional";
        case STPSourceCard3DSecureStatusNotSupported:
            return @"notSupported";
        case STPSourceCard3DSecureStatusUnknown:
        default:
            return @"unknown";
    }
}

- (STPAddress *)address:(NSDictionary*)inputAddress {
    STPAddress *address = [[STPAddress alloc] init];
    
    [address setName:inputAddress[@"name"]];
    [address setLine1:inputAddress[@"line1"]];
    [address setLine2:inputAddress[@"line2"]];
    [address setCity:inputAddress[@"city"]];
    [address setState:inputAddress[@"state"]];
    [address setPostalCode:inputAddress[@"postalCode"]];
    [address setCountry:inputAddress[@"country"]];
    [address setPhone:inputAddress[@"phone"]];
    [address setEmail:inputAddress[@"email"]];
    
    return address;
}

- (NSString *)sourceStatus:(STPSourceStatus)inputStatus {
    switch (inputStatus) {
        case STPSourceStatusPending:
            return @"pending";
        case STPSourceStatusChargeable:
            return @"chargable";
        case STPSourceStatusConsumed:
            return @"consumed";
        case STPSourceStatusCanceled:
            return @"canceled";
        case STPSourceStatusFailed:
            return @"failed";
        case STPSourceStatusUnknown:
        default:
            return @"unknown";
    }
}

- (NSString *)sourceUsage:(STPSourceUsage)inputUsage {
    switch (inputUsage) {
        case STPSourceUsageReusable:
            return @"reusable";
        case STPSourceUsageSingleUse:
            return @"singleUse";
        case STPSourceUsageUnknown:
        default:
            return @"unknown";
    }
}

@end

