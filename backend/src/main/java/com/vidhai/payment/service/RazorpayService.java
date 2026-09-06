package com.vidhai.payment.service;

import com.razorpay.Order;
import com.razorpay.RazorpayClient;
import com.vidhai.payment.dto.CreateOrderResponse;
import org.json.JSONObject;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class RazorpayService {

    private final RazorpayClient razorpayClient;

    public RazorpayService(
            @Value("${razorpay.key.id}") String keyId,
            @Value("${razorpay.key.secret}") String keySecret
    ) throws Exception {

        this.razorpayClient =
                new RazorpayClient(
                        keyId,
                        keySecret
                );
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

        JSONObject orderRequest =
                new JSONObject();

        orderRequest.put(
                "amount",
                amount
        );

        orderRequest.put(
                "currency",
                "INR"
        );

        orderRequest.put(
                "receipt",
                receipt
        );

        orderRequest.put(
                "payment_capture",
                1
        );

        Order order =
                razorpayClient.orders.create(
                        orderRequest
                );

        return new CreateOrderResponse(
                order.get("id"),
                amount,
                "INR"
        );
    }
}