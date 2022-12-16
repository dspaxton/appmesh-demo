FROM public.ecr.aws/amazonlinux/amazonlinux:latest
RUN yum -y update && yum -y install python3-pip shadow-utils && \
pip3 install requests cherrypy boto3 ec2-metadata && \
yum clean all && useradd app && mkdir /public && chown -R app /public
ADD public /public/
COPY app.py /
USER app
EXPOSE 8080
CMD ["python3","app.py"]

