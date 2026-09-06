package com.vidhai.payment.service;

import com.razorpay.Order;
import com.razorpay.RazorpayClient;
import com.razorpay.Utils;
import com.vidhai.payment.dto.CreateOrderResponse;
import com.vidhai.payment.dto.VerifyPaymentResponse;
import org.json.JSONObject;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class RazorpayService {

    private final RazorpayClient razorpayClient;
    private final String keySecret;

    public RazorpayService(
            @Value("${razorpay.key.id}") String keyId,
            @Value("${razorpay.key.secret}") String keySecret
    ) throws Exception {
        this.keySecret = keySecret;
        this.razorpayClient = new RazorpayClient(keyId, keySecret);
    }

    public CreateOrderResponse createOrder(
            Long amount,
            String receipt
    ) throws Exception {

        if (amount == null || amount <= 0) {
            throw new IllegalArgumentException(
                    "Amount must be greater than zero"
            );
        }

        JSONObject orderRequest = new JSONObject();
        orderRequest.put("amount", amount);
        orderRequest.put("currency", "INR");
        orderRequest.put("receipt", receipt);
        orderRequest.put("payment_capture", 1);

        Order order = razorpayClient.orders.create(orderRequest);

        return new CreateOrderResponse(
                order.get("id"),
                amount,
                "INR"
        );
    }

    public VerifyPaymentResponse verifyPayment(
            String orderId,
            String paymentId,
            String signature
    ) {
        if (orderId == null || orderId.trim().isEmpty() ||
            paymentId == null || paymentId.trim().isEmpty() ||
            signature == null || signature.trim().isEmpty()) {
            return new VerifyPaymentResponse(false, "Missing required payment verification parameters");
        }

        try {
            JSONObject options = new JSONObject();
            options.put("razorpay_order_id", orderId);
            options.put("razorpay_payment_id", paymentId);
            options.put("razorpay_signature", signature);

            boolean isSignatureValid = Utils.verifyPaymentSignature(options, this.keySecret);

            if (isSignatureValid) {
                return new VerifyPaymentResponse(true, "Payment verified successfully");
            } else {
                return new VerifyPaymentResponse(false, "Invalid Razorpay signature");
            }
        } catch (Exception e) {
            return new VerifyPaymentResponse(false, "Verification error: " + e.getMessage());
        }
    }
}