#!/usr/bin/env python3
import subprocess
import sys
import os
from datetime import datetime

def run_performance_test(test_type="standard", host="http://localhost"):
    config = {
        "light": {"users": 10, "spawn_rate": 1, "duration": 60},
        "standard": {"users": 20, "spawn_rate": 2, "duration": 120},
        "stress": {"users": 50, "spawn_rate": 5, "duration": 300}
    }
    
    if test_type not in config:
        print(f"Tipo de prueba no válido: {test_type}")
        return False
    
    cfg = config[test_type]
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    cmd = [
        "locust",
        "-f", "locustfile.py",
        "--headless",
        "--users", str(cfg["users"]),
        "--spawn-rate", str(cfg["spawn_rate"]),
        "--run-time", f"{cfg['duration']}s",
        "--host", host,
        "--html", f"results/{test_type}_report_{timestamp}.html",
        "--csv", f"results/{test_type}_data_{timestamp}"
    ]
    
    print(f"Ejecutando prueba {test_type}...")
    try:
        result = subprocess.run(cmd, timeout=cfg["duration"]+60)
        return result.returncode == 0
    except Exception as e:
        print(f"Error: {e}")
        return False

if __name__ == "__main__":
    test_type = sys.argv[1] if len(sys.argv) > 1 else "standard"
    host = sys.argv[2] if len(sys.argv) > 2 else "http://localhost"
    
    success = run_performance_test(test_type, host)
    sys.exit(0 if success else 1)
