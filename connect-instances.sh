#!/bin/bash

echo "🔌 Instancias disponibles:"
echo "1. ecommerce-microservice-dev-instance-1"
echo "2. ecommerce-microservice-dev-instance-2" 
echo "3. ecommerce-microservice-dev-instance-3"
echo ""

read -p "¿A cuál instancia quieres conectarte? (1-3): " choice

case $choice in
    1)
        echo "Conectando a instancia 1..."
        gcloud compute ssh ecommerce-microservice-dev-instance-1 --zone=us-central1-a
        ;;
    2)
        echo "Conectando a instancia 2..."
        gcloud compute ssh ecommerce-microservice-dev-instance-2 --zone=us-central1-a
        ;;
    3)
        echo "Conectando a instancia 3..."
        gcloud compute ssh ecommerce-microservice-dev-instance-3 --zone=us-central1-a
        ;;
    *)
        echo "Opción inválida"
        ;;
esac
