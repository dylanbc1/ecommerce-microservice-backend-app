# tests/performance/locustfile.py
from locust import HttpUser, task, between
import random
import json
from datetime import datetime

class EcommerceUser(HttpUser):
    """
    Simula un usuario típico del e-commerce que navega, busca productos,
    añade items al carrito y realiza compras.
    """
    wait_time = between(1, 3)
    weight = 8  # 80% de los usuarios serán usuarios normales
    
    def on_start(self):
        """Setup inicial: crear/login usuario"""
        self.user_id = None
        self.token = None
        self.create_or_login_user()
    
    def create_or_login_user(self):
        """Crear un nuevo usuario o usar uno existente"""
        # Intentar crear usuario
        user_data = {
            "username": f"user_{random.randint(1000, 9999)}",
            "email": f"user_{random.randint(1000, 9999)}@test.com",
            "password": "password123",
            "firstName": "Test",
            "lastName": "User"
        }
        
        with self.client.post("/app/api/users/register", 
                             json=user_data, 
                             catch_response=True,
                             name="User Registration") as response:
            if response.status_code in [200, 201]:
                user_info = response.json()
                self.user_id = user_info.get("id")
                response.success()
            else:
                # Si falla, usar un usuario por defecto
                self.user_id = random.randint(1, 100)
                response.failure(f"Registration failed: {response.status_code}")
    
    @task(4)
    def browse_products(self):
        """Navegación de productos - tarea más común"""
        # Listar productos
        with self.client.get("/app/api/products", 
                           catch_response=True,
                           name="Browse Products") as response:
            if response.status_code == 200:
                response.success()
                products = response.json()
                
                # Ver detalles de un producto específico
                if products and len(products) > 0:
                    product_id = random.choice(products).get("id", 1)
                    self.view_product_details(product_id)
            else:
                response.failure(f"Browse failed: {response.status_code}")
    
    def view_product_details(self, product_id):
        """Ver detalles de un producto específico"""
        with self.client.get(f"/app/api/products/{product_id}",
                           catch_response=True,
                           name="View Product Details") as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Product details failed: {response.status_code}")
    
    @task(3)
    def search_products(self):
        """Búsqueda de productos"""
        search_terms = ["laptop", "phone", "book", "shirt", "electronics", "clothing"]
        search_term = random.choice(search_terms)
        
        with self.client.get(f"/app/api/products/search",
                           params={"q": search_term},
                           catch_response=True,
                           name="Search Products") as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Search failed: {response.status_code}")
    
    @task(2)
    def view_categories(self):
        """Ver categorías de productos"""
        with self.client.get("/app/api/categories",
                           catch_response=True,
                           name="View Categories") as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Categories failed: {response.status_code}")
    
    @task(1)
    def create_order(self):
        """Crear una orden - flujo completo de compra"""
        if not self.user_id:
            return
        
        # Obtener un producto aleatorio
        product_id = random.randint(1, 10)
        quantity = random.randint(1, 3)
        
        order_data = {
            "userId": self.user_id,
            "orderItems": [
                {
                    "productId": product_id,
                    "quantity": quantity,
                    "unitPrice": random.uniform(10.0, 100.0)
                }
            ]
        }
        
        with self.client.post("/app/api/orders",
                            json=order_data,
                            catch_response=True,
                            name="Create Order") as response:
            if response.status_code in [200, 201]:
                response.success()
                order = response.json()
                
                # Procesar pago si la orden se creó exitosamente
                if order and order.get("id"):
                    self.process_payment(order["id"], order.get("totalAmount", 50.0))
            else:
                response.failure(f"Order creation failed: {response.status_code}")
    
    def process_payment(self, order_id, amount):
        """Procesar pago para una orden"""
        payment_data = {
            "orderId": order_id,
            "amount": amount,
            "paymentMethod": random.choice(["CREDIT_CARD", "DEBIT_CARD", "PAYPAL"])
        }
        
        with self.client.post("/app/api/payments",
                            json=payment_data,
                            catch_response=True,
                            name="Process Payment") as response:
            if response.status_code in [200, 201]:
                response.success()
            else:
                response.failure(f"Payment failed: {response.status_code}")
    
    @task(1)
    def view_user_orders(self):
        """Ver órdenes del usuario"""
        if not self.user_id:
            return
        
        with self.client.get(f"/app/api/users/{self.user_id}/orders",
                           catch_response=True,
                           name="View User Orders") as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"User orders failed: {response.status_code}")


class AdminUser(HttpUser):
    """
    Simula un usuario administrador que realiza operaciones de gestión.
    """
    wait_time = between(3, 8)
    weight = 1  # 10% de los usuarios serán administradores
    
    def on_start(self):
        """Login como administrador"""
        self.login_admin()
    
    def login_admin(self):
        """Login con credenciales de administrador"""
        admin_data = {
            "username": "admin",
            "password": "admin123"
        }
        
        with self.client.post("/app/api/auth/login",
                            json=admin_data,
                            catch_response=True,
                            name="Admin Login") as response:
            if response.status_code == 200:
                self.token = response.json().get("token")
                response.success()
            else:
                response.failure(f"Admin login failed: {response.status_code}")
    
    @task(3)
    def view_all_orders(self):
        """Ver todas las órdenes (operación admin)"""
        headers = {"Authorization": f"Bearer {self.token}"} if self.token else {}
        
        with self.client.get("/app/api/admin/orders",
                           headers=headers,
                           catch_response=True,
                           name="Admin View All Orders") as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Admin orders view failed: {response.status_code}")
    
    @task(2)
    def view_statistics(self):
        """Ver estadísticas del sistema"""
        headers = {"Authorization": f"Bearer {self.token}"} if self.token else {}
        
        with self.client.get("/app/api/admin/statistics",
                           headers=headers,
                           catch_response=True,
                           name="Admin View Statistics") as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Admin statistics failed: {response.status_code}")
    
    @task(1)
    def manage_products(self):
        """Gestión de productos (crear/actualizar)"""
        headers = {"Authorization": f"Bearer {self.token}"} if self.token else {}
        
        # Crear nuevo producto
        product_data = {
            "name": f"Test Product {random.randint(1000, 9999)}",
            "description": "Test product for load testing",
            "price": random.uniform(10.0, 200.0),
            "categoryId": random.randint(1, 5),
            "stock": random.randint(10, 100)
        }
        
        with self.client.post("/app/api/admin/products",
                            json=product_data,
                            headers=headers,
                            catch_response=True,
                            name="Admin Create Product") as response:
            if response.status_code in [200, 201]:
                response.success()
            else:
                response.failure(f"Product creation failed: {response.status_code}")


class HighVolumeUser(HttpUser):
    """
    Simula usuarios con alta actividad (para pruebas de estrés).
    """
    wait_time = between(0.5, 1.5)
    weight = 1  # Solo en pruebas de estrés
    
    @task
    def rapid_browsing(self):
        """Navegación rápida y repetitiva"""
        endpoints = [
            "/app/api/products",
            "/app/api/categories",
            "/app/api/products/1",
            "/app/api/products/2",
            "/app/api/products/search?q=test"
        ]
        
        endpoint = random.choice(endpoints)
        with self.client.get(endpoint,
                           catch_response=True,
                           name="Rapid Browsing") as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Rapid browsing failed: {response.status_code}")


# tests/performance/performance_runner.py
import subprocess
import sys
import os
import json
from datetime import datetime

class PerformanceTestRunner:
    """
    Ejecutor de pruebas de rendimiento con diferentes configuraciones.
    """
    
    def __init__(self, host="http://localhost", base_users=20):
        self.host = host
        self.base_users = base_users
        self.results_dir = "results"
        self.ensure_results_dir()
    
    def ensure_results_dir(self):
        """Crear directorio de resultados si no existe"""
        os.makedirs(self.results_dir, exist_ok=True)
    
    def run_light_test(self):
        """Prueba ligera - validación rápida"""
        print("🔵 Ejecutando prueba LIGHT...")
        return self._run_locust_test(
            users=10,
            spawn_rate=1,
            duration=60,
            test_type="light"
        )
    
    def run_standard_test(self):
        """Prueba estándar - CI/CD normal"""
        print("🟡 Ejecutando prueba STANDARD...")
        return self._run_locust_test(
            users=self.base_users,
            spawn_rate=2,
            duration=120,
            test_type="standard"
        )
    
    def run_stress_test(self):
        """Prueba de estrés - validación de límites"""
        print("🔴 Ejecutando prueba STRESS...")
        return self._run_locust_test(
            users=self.base_users * 3,
            spawn_rate=5,
            duration=300,
            test_type="stress"
        )
    
    def _run_locust_test(self, users, spawn_rate, duration, test_type):
        """Ejecutar prueba de Locust con parámetros específicos"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        cmd = [
            "locust",
            "-f", "locustfile.py",
            "--headless",
            "--users", str(users),
            "--spawn-rate", str(spawn_rate),
            "--run-time", f"{duration}s",
            "--host", self.host,
            "--html", f"{self.results_dir}/{test_type}_test_report_{timestamp}.html",
            "--csv", f"{self.results_dir}/{test_type}_test_data_{timestamp}",
            "--logfile", f"{self.results_dir}/{test_type}_test_log_{timestamp}.log"
        ]
        
        print(f"Comando: {' '.join(cmd)}")
        print(f"Configuración: {users} usuarios, {spawn_rate}/s spawn rate, {duration}s")
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=duration+120)
            
            # Crear resumen de resultados
            self._create_test_summary(test_type, timestamp, users, spawn_rate, duration, result)
            
            if result.returncode == 0:
                print(f"✅ Prueba {test_type} completada exitosamente")
                return True
            else:
                print(f"❌ Prueba {test_type} falló con código: {result.returncode}")
                print(f"STDERR: {result.stderr}")
                return False
                
        except subprocess.TimeoutExpired:
            print(f"⏰ Prueba {test_type} excedió el tiempo límite")
            return False
        except Exception as e:
            print(f"💥 Error ejecutando prueba {test_type}: {e}")
            return False
    
    def _create_test_summary(self, test_type, timestamp, users, spawn_rate, duration, result):
        """Crear resumen de la prueba ejecutada"""
        summary = {
            "test_type": test_type,
            "timestamp": timestamp,
            "configuration": {
                "users": users,
                "spawn_rate": spawn_rate,
                "duration": duration,
                "host": self.host
            },
            "execution": {
                "return_code": result.returncode,
                "stdout": result.stdout,
                "stderr": result.stderr
            },
            "files_generated": [
                f"{test_type}_test_report_{timestamp}.html",
                f"{test_type}_test_data_{timestamp}_stats.csv",
                f"{test_type}_test_data_{timestamp}_failures.csv",
                f"{test_type}_test_log_{timestamp}.log"
            ]
        }
        
        summary_file = f"{self.results_dir}/{test_type}_summary_{timestamp}.json"
        with open(summary_file, 'w') as f:
            json.dump(summary, f, indent=2)
        
        print(f"📊 Resumen guardado en: {summary_file}")
    
    def run_all_tests(self):
        """Ejecutar todas las pruebas en secuencia"""
        print("🚀 Iniciando suite completa de pruebas de rendimiento...")
        
        results = {
            "light": self.run_light_test(),
            "standard": self.run_standard_test(),
            "stress": self.run_stress_test()
        }
        
        print("\n📊 RESUMEN FINAL:")
        for test_type, success in results.items():
            status = "✅ EXITOSA" if success else "❌ FALLIDA"
            print(f"  - {test_type.upper()}: {status}")
        
        return all(results.values())


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Ejecutor de pruebas de rendimiento")
    parser.add_argument("--host", default="http://localhost", help="Host objetivo")
    parser.add_argument("--users", type=int, default=20, help="Número base de usuarios")
    parser.add_argument("--test-type", choices=["light", "standard", "stress", "all"], 
                       default="standard", help="Tipo de prueba a ejecutar")
    
    args = parser.parse_args()
    
    runner = PerformanceTestRunner(host=args.host, base_users=args.users)
    
    if args.test_type == "light":
        success = runner.run_light_test()
    elif args.test_type == "standard":
        success = runner.run_standard_test()
    elif args.test_type == "stress":
        success = runner.run_stress_test()
    elif args.test_type == "all":
        success = runner.run_all_tests()
    else:
        print("❌ Tipo de prueba no válido")
        sys.exit(1)
    
    sys.exit(0 if success else 1)