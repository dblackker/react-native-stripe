
package com.reactlibrary;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Promise;

import com.facebook.react.bridge.ReadableMap;

import com.stripe.android.SourceCallback;
import com.stripe.android.Stripe;
import com.stripe.android.TokenCallback;
import com.stripe.android.model.Source;
import com.stripe.android.model.SourceParams;
import com.stripe.android.model.Token;


public class RNStripeModule extends ReactContextBaseJavaModule {
  private static final String TAG = "com.reactlibrary.stripe";
  private final ReactApplicationContext reactContext;

  private Stripe stripe;

  public RNStripeModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
  }

  @ReactMethod
  public void init(ReadableMap options) {
    String publicKey = options.getString("publishableKey");
    stripe = new Stripe(reactContext.getBaseContext(), publicKey);
  }

  @ReactMethod
  public void createTokenWithCard(final ReadableMap card, final Promise promise) {
    try {
      stripe.createToken(Converters.createCard(card),
           new TokenCallback() {
           public void onSuccess(Token token) {
             promise.resolve(Converters.convertTokenToWritableMap(token));
           }

           public void onError(Exception error) {
             error.printStackTrace();
             promise.reject(TAG, error.getMessage());
           }
         });
    } catch (Exception e) {
      promise.reject(TAG, e.getMessage());
    }
  }

  @ReactMethod
  public void createTokenWithBank(final ReadableMap bank, final Promise promise) {
    try {
      stripe.createBankAccountToken(Converters.createBankAccount(bank),
           new TokenCallback() {
           public void onSuccess(Token token) {
             promise.resolve(Converters.convertTokenToWritableMap(token));
           }

           public void onError(Exception error) {
             error.printStackTrace();
             promise.reject(TAG, error.getMessage());
           }
         });
    } catch (Exception e) {
      promise.reject(TAG, e.getMessage());
    }
  }

 @ReactMethod
 public void createSourceWithCard(final ReadableMap card, final Promise promise) {
   try {
     SourceParams cardSourceParams = SourceParams.createCardParams(Converters.createCard(card));
     stripe.createSource(cardSourceParams,
         new SourceCallback() {
           public void onSuccess(Source source) {
             promise.resolve(Converters.convertSourceToWritableMap(source));
           }

           public void onError(Exception error) {
             error.printStackTrace();
             promise.reject(TAG, error.getMessage());
           }
         });
   } catch (Exception e) {
     promise.reject(TAG, e.getMessage());
   }
 }

  @Override
  public String getName() {
    return "RNStripe";
  }
}
