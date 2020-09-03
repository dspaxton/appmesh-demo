#!/usr/bin/env python3
import os, os.path
import urllib.request
from urllib.parse import urlparse
import cherrypy
import json
import requests
import pdb

# catalog = os.environ['CATALOG']
# access_key = os.environ['AWS_ACCESS_KEY_ID']
# secret_key = os.environ['AWS_SECRET_ACCESS_KEY']
# session_token = os.environ['AWS_SESSION_TOKEN']



class frontend(object):
    @cherrypy.expose
    def index(self):
        backendresponse = urllib.request.urlopen('http://backend.my-apps.svc.cluster.local:8080/')
        backendoutput = backendresponse.read().decode('utf-8')
        response = urllib.request.urlopen('http://db.my-apps.svc.cluster.local:8080/')
        output = response.read().decode('utf-8')
        html = """<html>
        <center>
          <head>
            <link href="/static/css/style.css" rel="stylesheet">
          </head>
          <h1>FrontEnd</h1>
          <body>
          <p>Welcome
          """
        html += str(backendoutput) + "<BR>"
        html += "Latest stock info:" + str(output)
        html += """</head>
          </html>
          """
        return html

    @cherrypy.expose
    def backend(self):
        # url = 
        # url = "http://backendv1:8080/"
        # r = urllib.request.Request(url)
        # resp = urllib.request.urlopen(r)
        # respData = resp.read()
        #r = requests.get(url)
        #output = r.json()
        #output = print(r.text)
        response = urllib.request.urlopen('http://backend:8080/')
        output = response.read().decode('utf-8')
        html = """<html>
        <center>
          <head>
            <link href="/static/css/style.css" rel="stylesheet">
          </head>
          <h1><a href="/">FrontEnd</a></h1>
          <body>
          <p>
          """
        html += str(output)

        print(html)
        return html
        
        
    @cherrypy.expose
    def display_requests(self):
        #catalog = os.environ['CATALOG']
        #print(catalog)
        url = "http://requests/"
        r = requests.get(url)
        output = r.json()
        # print(type(output))
        # print(output)
        html = """<html>
        <center>
          <head>
            <link href="/static/css/style.css" rel="stylesheet">
          </head>
          <h1><a href="/">FrontEnd</a></h1>
          <body>
          <p>
          <table>
          """
        for line in output:
            id = line['opid']
            subject = line['Subject']
            desc = line['Opportunity']
            requester = line['Name']
            html += "<tr><td><a href='/request/" + id + "'>" + subject + "</a></td></tr>"
            # html += 'You are trying to book' + id + 'for' + desc + 'yes?' 
            # print(line['ProductID'])
        html += "</table>"
        print(html)
        return html

    @cherrypy.expose
    def request(self,*url_parts,**params):
        req = cherrypy.request
        print(url_parts)
        reqtype = url_parts[0]
        body = 'Page URL is: %s' % req.path_info
        #parts = url_parts.split('/')
        html = """
        <html>
        <center>
          <head>
            <link href="/static/css/style.css" rel="stylesheet">
          </head>
          <h1><a href="/">FrontEnd</a></h1>
          <body>
          <p>
          <table>
          <form method="get" action="/submit">
            <table>
            <tr><td>Name</td></tr>
          
            <tr><td><input type="text" length="20" name="name" /></td><tr>
              <tr><td>One-liner</td></tr>
            <tr><td><input type="text" length="20" name="subject"</td></tr>
              <tr><td>Details</td></tr>
            <tr><td><textarea rows="4" cols=40 name="details" />Please enter your details (maximum 100 words)</textarea></td></tr>
            </table>
            """
        html += '<input type="hidden" name="reqtype" value="' + reqtype + '">'
        html += '<button type="submit">Submit</button>'
        return html

    @cherrypy.expose
    def submit(self,name,subject,details,reqtype):
        my_session = boto3.session.Session()
        region = my_session.region_name
        az = os.popen("curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone/").read()
        region = az[:-1]
        account = boto3.client('sts').get_caller_identity().get('Account')
        message = details
        print(name)
        print(details)
        print(reqtype)
        print(account)
        print(region)
        topicarn = "arn:aws:sns:" + region + ":" + account +":"+reqtype
        print(topicarn)
        client = boto3.client('sns',region_name=region)
        response = client.publish(
            TopicArn=topicarn,
            Message=message,
            MessageAttributes={
                'userid': {
                    'DataType': 'String',
                    'StringValue': name 
                },
                'subject': {
                  'DataType': 'String',
                  'StringValue': subject
                }
            }
        )
        print(response)
        html = """
        <html>
        <center>
          <head>
            <link href="/static/css/style.css" rel="stylesheet">
          </head>
          <h1><a href="/">FrontEnd</a></h1>
          <body>
          <p>
          Request submitted.
          """
        return html



if __name__ == '__main__':
    conf = {
        '/': {
            'tools.sessions.on': True,
            'tools.response_headers.on': True,
            # 'tools.response_headers.headers': [('Content-Type', 'text/plain')],
            'tools.staticdir.root': os.path.abspath(os.getcwd())
        },
        '/static': {
            'tools.staticdir.on': True,
            'tools.staticdir.dir': './public'
        }
    }
    #cherrypy.quickstart(tradechecker(), '/', conf)
    cherrypy.config.update({'server.socket_host':'0.0.0.0','server.socket_port':8080})
    cherrypy.quickstart(frontend(), '/', conf)
