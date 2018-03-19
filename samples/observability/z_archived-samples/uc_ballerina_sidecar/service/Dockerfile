FROM python:3.4-alpine

RUN pip install Flask==0.10.1

RUN mkdir -p /opt/microservices
ADD app.py /opt/microservices/

EXPOSE 5000

WORKDIR /opt/microservices
CMD python app.py
