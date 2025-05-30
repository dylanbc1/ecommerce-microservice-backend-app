from locust import HttpUser, task, between
import random

class EcommerceUser(HttpUser):
    wait_time = between(1, 3)
    
    @task(3)
    def browse_products(self):
        self.client.get("/app/api/products")
        
        # Ver producto específico
        product_id = random.randint(1, 10)
        self.client.get(f"/app/api/products/{product_id}")
    
    @task(2)
    def search_products(self):
        search_terms = ["laptop", "phone", "book"]
        term = random.choice(search_terms)
        self.client.get(f"/app/api/products/search?q={term}")
    
    @task(1)
    def view_categories(self):
        self.client.get("/app/api/categories")
