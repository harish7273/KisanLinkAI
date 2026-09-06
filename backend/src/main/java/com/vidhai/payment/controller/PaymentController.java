package com.vidhai.payment.controller;

import com.vidhai.payment.dto.CreateOrderRequest;
import com.vidhai.payment.dto.CreateOrderResponse;
import com.vidhai.payment.dto.VerifyPaymentRequest;
import com.vidhai.payment.dto.VerifyPaymentResponse;
import com.vidhai.payment.service.RazorpayService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/payment")
@CrossOrigin(origins = "*")
public class PaymentController {

    private final RazorpayService razorpayService;

    public PaymentController(RazorpayService razorpayService) {
        this.razorpayService = razorpayService;
    }

    @PostMapping("/create-order")
    public ResponseEntity<?> createOrder(@RequestBody CreateOrderRequest request) {
        try {
            CreateOrderResponse response = razorpayService.createOrder(
                    request.getAmount(),
                    request.getReceipt()
            );
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PostMapping("/verify")
    public ResponseEntity<VerifyPaymentResponse> verifyPayment(@RequestBody VerifyPaymentRequest request) {
        try {
            VerifyPaymentResponse response = razorpayService.verifyPayment(
                    request.getRazorpayOrderId(),
                    request.getRazorpayPaymentId(),
                    request.getRazorpaySignature()
            );

            if (response.isVerified()) {
                return ResponseEntity.ok(response);
            } else {
                return ResponseEntity.badRequest().body(response);
            }
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(
                    new VerifyPaymentResponse(false, "Internal error: " + e.getMessage())
            );
        }
    }
}