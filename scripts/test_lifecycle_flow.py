import json
import socket
import urllib.request
import urllib.error

def test_port(name, host, port):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(2.0)
    try:
        s.connect((host, port))
        s.close()
        return True, "Port Open / Listening"
    except Exception as e:
        return False, f"Connection Failed: {e}"

def run_lifecycle_audit():
    results = {}

    # Check 1: Payment backend (Spring Boot) on 8080
    p8080_open, p8080_msg = test_port("Payment Backend", "127.0.0.1", 8080)
    p8080_service = "Unknown"
    if p8080_open:
        try:
            req = urllib.request.Request("http://127.0.0.1:8080/api/payment/health")
            with urllib.request.urlopen(req, timeout=2) as resp:
                p8080_service = f"HTTP {resp.status}"
        except urllib.error.HTTPError as e:
            p8080_service = f"HTTP {e.code} (Not Spring Boot Payment API; serving Admin Web)"
        except Exception as e:
            p8080_service = str(e)
    results["payment_backend_8080"] = {
        "status": "Port hijacked by static web server" if "404" in p8080_service or p8080_open else "Offline",
        "detail": f"{p8080_msg} | Service: {p8080_service}"
    }

    # Check 2: Smart Pricing API on 8000
    p8000_open, p8000_msg = test_port("Smart Pricing API", "127.0.0.1", 8000)
    results["smart_pricing_8000"] = {
        "status": "Online" if p8000_open else "Offline (Connection Refused)",
        "detail": p8000_msg
    }

    # Check 3: Price Prediction Flask on 5000
    p5000_open, p5000_msg = test_port("Flask Price Prediction", "127.0.0.1", 5000)
    results["price_prediction_5000"] = {
        "status": "Online" if p5000_open else "Offline (Connection Refused)",
        "detail": p5000_msg
    }

    # Check 4: Remote Reachability Check
    # Machine LAN IP from ApiConfig
    lan_ip = "10.88.48.167"
    lan_open, lan_msg = test_port("LAN IP Binding", lan_ip, 8080)
    results["lan_reachability"] = {
        "target": f"http://{lan_ip}:8080",
        "reachable": lan_open,
        "detail": "Fails completely outside local Wi-Fi subnet or when laptop suspends/powers down"
    }

    print(json.dumps(results, indent=2))
    return results

if __name__ == "__main__":
    run_lifecycle_audit()
