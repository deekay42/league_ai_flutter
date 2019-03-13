package com.leagueiq.app;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import com.braintreepayments.api.dropin.DropInActivity;
import com.braintreepayments.api.dropin.DropInRequest;
import com.braintreepayments.api.dropin.DropInResult;
import com.braintreepayments.api.dropin.utils.PaymentMethodType;
import com.braintreepayments.api.models.PayPalRequest;
import com.braintreepayments.api.models.VenmoAccountNonce;

import java.util.ArrayList;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
    private final static int REQUEST_CODE = 424242;
    private static final String CHANNEL = "getPaymentNonce";
    private static final String MYTAG = "ANDROIDCHANNEL";

    Result btresult;

    private void startPaymentSelection(String clientToken)
    {
        DropInRequest dropInRequest = new DropInRequest()
                .clientToken(clientToken)
//                .amount("1.00")
//                .requestThreeDSecureVerification(true)
                .collectDeviceData(true);
        PayPalRequest paypalRequest = new PayPalRequest();
        paypalRequest.userAction("BUYYYY");
        dropInRequest.paypalRequest(paypalRequest);
//        enableGooglePay(dropInRequest);

        startActivityForResult(dropInRequest.getIntent(MainActivity.this), REQUEST_CODE);
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        Log.d(MYTAG, "Activity finished");
        if (requestCode == REQUEST_CODE) {
            Log.d(MYTAG, "It was the payment activity");
            if (resultCode == Activity.RESULT_OK) {
                Log.d(MYTAG, "Everything worked!");
                // use the result to update your UI and send the payment method nonce to your server
                DropInResult result = data.getParcelableExtra(DropInResult.EXTRA_DROP_IN_RESULT);
                String deviceData = result.getDeviceData();

                if (result.getPaymentMethodType() == PaymentMethodType.PAY_WITH_VENMO) {
                    VenmoAccountNonce venmoAccountNonce = (VenmoAccountNonce) result.getPaymentMethodNonce();
                    String venmoUsername = venmoAccountNonce.getUsername();
                }

                Log.d(MYTAG, "Gathering stuff now");
                String nonce = result.getPaymentMethodNonce().getNonce();
                //Integer icon = Integer.toString(result.getPaymentMethodType().getDrawable());
                String desc = result.getPaymentMethodNonce().getDescription();
                String type = result.getPaymentMethodNonce().getTypeLabel();
                // String type = result.getPaymentMethodType.getCanonicalName();
                java.util.ArrayList<String> res = new ArrayList<String>();;
                res.add(nonce);
                res.add(type + " " + desc);
                btresult.success(res);

            } else if (resultCode == Activity.RESULT_CANCELED) {
                Log.d(MYTAG, "It was canceled");
                btresult.success(null);
            } else {
                Log.e(MYTAG, "There was an error");
                // Handle errors here, an exception may be available in
                Exception error = (Exception) data.getSerializableExtra(DropInActivity.EXTRA_ERROR);
                Log.e(MYTAG, error.toString());
                btresult.error("ERROR", error.toString(), null);
            }
        }
        else
            super.onActivityResult(requestCode, resultCode, data);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        GeneratedPluginRegistrant.registerWith(this);

        new MethodChannel(getFlutterView(), CHANNEL).setMethodCallHandler(
                new MethodCallHandler() {
                    @Override
                    public void onMethodCall(MethodCall call, Result result) {
                        if (call.method.equals("getPaymentNonce")) {

                            String clientToken = call.argument("clientToken");
                            btresult = result;
                            startPaymentSelection(clientToken);

                        } else {
                            result.notImplemented();
                        }
                    }
                });
    }
}
