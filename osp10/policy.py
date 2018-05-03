#!/usr/bin/python
import json
import argparse
from pprint import pprint

parser = argparse.ArgumentParser(description='Convert existing policy.json file to YAML template.')
parser.add_argument('policy_json', help='JSON policy file to convert')
parser.add_argument('service_name', help='Service name for the policy (nova, heat, ironic...)')
parser.add_argument('-o', dest='output_file', required=False, help='Output file. Default is $service-policy.yaml')
args = parser.parse_args()

if args.output_file is None:
    output_file = args.service_name+"_policy.yaml"

with open(args.policy_json, 'r') as f:
    policy_data = json.load(f)

service=args.service_name
header = """parameter_defaults:
    ControllerExtraConfig:
        {service}::policy::policies: {{""".format(service=service)
body = ""
num = len(policy_data.keys())

for key in policy_data.keys():
    value = policy_data[key]
    # .replace("'","\\'")
    num -= 1
    if num > 0:
        data = """ 
            "{service}-{key}": {{
              "key": "{key}",
              "value": "{value}"
              }},""".format(key=key, value=value, service=service)
    else:
        data = """ 
            "{service}-{key}": {{
              "key": "{key}",
              "value": "{value}"
              }}
        }}\n""".format(key=key, value=value, service=service)
 
    body += data

with open(output_file, 'w') as f:
    f.write(header+body)

