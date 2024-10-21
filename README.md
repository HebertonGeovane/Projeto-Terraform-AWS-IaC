# Projeto-Terraform-AWS-IaC 💻 ☁️ 🔸
_____________________________________________________________________
## Estou animado em compartilhar  Projeto  Terraform AWS IaC.

Construí uma Arquitetura altamente disponível e resiliente na AWS! 

1️⃣ . VPC e Sub-redes

🔸VPC (Virtual Private Cloud): Criamos uma VPC dedicada com CIDR 10.0.0.0/16, permitindo controle total sobre a rede.

🔸Sub-redes: Implementamos sub-redes públicas e privadas. As sub-redes públicas são usadas para instâncias EC2 e o Load Balancer, enquanto as sub-redes privadas hospedam o banco de dados RDS.

2️⃣ . Load Balancer e Auto Scaling

🔸Application Load Balancer (ALB): Distribui o tráfego entre instâncias EC2 em diferentes zonas de disponibilidade (AZ), aumentando a resiliência e a disponibilidade.

🔸Auto Scaling Group: Garante que o número de instâncias EC2 seja ajustado automaticamente com base na demanda, proporcionando escalabilidade e eficiência.

3️⃣ . Banco de Dados RDS

🔸Instâncias RDS Multi-AZ: Implementamos uma instância RDS para garantir alta disponibilidade. O uso de Multi-AZ permite que as réplicas do banco de dados sejam criadas em diferentes zonas, oferecendo recuperação rápida em caso de falhas.

4️⃣ . Segurança

🔸Grupos de Segurança: Definimos regras rígidas de entrada e saída, garantindo que apenas o tráfego necessário possa acessar os recursos. 

O acesso ao RDS é limitado às instâncias EC2 específicas, aumentando a segurança.

5️⃣ . Monitoramento e Notificações

🔸CloudWatch: Alarmes configurados para monitorar o uso da CPU e acionar políticas de escalonamento, garantindo que a infraestrutura se ajuste automaticamente.

🔸SNS (Simple Notification Service): Notificações por e-mail são enviadas para alertar sobre eventos críticos, como alterações no Auto Scaling.

6️⃣ . S3 Buckets

🔸Amazon S3: Um bucket S3 é criado e projetado para oferecer armazenamento escalável e durável.

Esta arquitetura não apenas garante alta disponibilidade e resiliência, mas também é escalável e segura. É ideal para aplicações que demandam performance consistente e precisam estar sempre disponíveis. O uso do Terraform facilita a automação e a replicação da infraestrutura, tornando o gerenciamento mais eficiente.

_____________________________________________________________________


![image](https://github.com/user-attachments/assets/6d3d09de-a6c4-477f-bff6-26f12aa663b8)

![image](https://github.com/user-attachments/assets/6f5cb4ed-dcb4-410f-a7aa-b459a1a34da6)

![image](https://github.com/user-attachments/assets/d70e2bc9-216d-46fa-84b3-c7d06fd6babc)

![image](https://github.com/user-attachments/assets/8c7e2e6d-6121-429e-b04a-edb86d7ce52a)

![image](https://github.com/user-attachments/assets/65a114a0-6e69-48f1-a1ce-61add47ad05b)

![image](https://github.com/user-attachments/assets/35ad640e-3a30-4ec4-b5f7-d1b3438576d8)

![image](https://github.com/user-attachments/assets/eaaf81e1-dd43-4ab2-8048-b0e1a37b9169)

![image](https://github.com/user-attachments/assets/0a7ec888-26ba-4724-9fa4-c23ab11cb408)

![image](https://github.com/user-attachments/assets/986dae0c-e446-4cbc-aea3-04198ac49b04)

![image](https://github.com/user-attachments/assets/5ac22178-93a3-4b98-a49c-ea26afc98253)

![image](https://github.com/user-attachments/assets/f623f6f6-7144-4891-a975-ac9dcf6f73e2)








