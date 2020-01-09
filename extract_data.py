import os
import sys
import csv
import json
import argparse
import logging
import boto3
from stravalib.client import Client
import requests

FORMAT = '%(funcName)1s - # %(lineno)s - %(message)s'
logging.basicConfig(format=FORMAT)
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

DEFAULT_BUCKET = 'eni-demo-rawdata'
DEFAULT_REGION = 'eu-west-1'


def extract_data(s3_client, keys, activity_key_name):

    activity_obj = s3_client.get_object(Bucket=DEFAULT_BUCKET, Key=activity_key_name)
    json_activity = json.loads(activity_obj['Body'].read().decode('utf-8'))

    wanted_data = {k: json_activity.get(k, None) for k in keys}

    start_latlng = wanted_data.get('start_latlng')
    end_latlng = wanted_data.get('end_latlng')
    start_lat = start_latlng[0] if start_latlng else None
    start_lng = start_latlng[1] if start_latlng else None
    end_lat = end_latlng[0] if end_latlng else None
    end_lng = end_latlng[1] if end_latlng else None
    athlete_id = wanted_data['athlete']['id']
    resource_state = wanted_data['athlete']['resource_state']

    extracted_data = [
        athlete_id, 'STRAVA', resource_state, wanted_data['name'],
        wanted_data['distance'],
        wanted_data['moving_time'],
        wanted_data['elapsed_time'],
        wanted_data['total_elevation_gain'],
        wanted_data['type'],
        wanted_data['id'],
        wanted_data['external_id'],
        wanted_data['upload_id'],
        wanted_data['start_date'],
        wanted_data['start_date_local'],
        wanted_data['timezone'],
        wanted_data['utc_offset'],
        start_lat,
        start_lng,
        end_lat,
        end_lng,
        wanted_data['achievement_count'],
        wanted_data['kudos_count'],
        wanted_data['comment_count'],
        wanted_data['athlete_count'],
        wanted_data['photo_count'],
        wanted_data['trainer'],
        wanted_data['commute'],
        wanted_data['manual'],
        wanted_data['private'],
        wanted_data['visibility'],
        wanted_data['flagged'],
        wanted_data['gear_id'],
        wanted_data['from_accepted_tag'],
        wanted_data['upload_id_str'],
        wanted_data['average_speed'],
        wanted_data['max_speed'],
        wanted_data['average_cadence'],
        wanted_data['average_watts'],
        wanted_data['weighted_average_watts'],
        wanted_data['kilojoules'],
        wanted_data['device_watts'],
        wanted_data['has_heartrate'],
        wanted_data['heartrate_opt_out'],
        wanted_data['display_hide_heartrate_option'],
        wanted_data['max_watts'],
        wanted_data['elev_high'],
        wanted_data['elev_low'],
        wanted_data['pr_count'],
        wanted_data['total_photo_count'],
        wanted_data['has_kudoed'],
        wanted_data['description'],
        wanted_data['calories'],
        wanted_data['perceived_exertion'],
        wanted_data['prefer_perceived_exertion'],
        wanted_data['device_name'],
        wanted_data['embed_token']
    ]

    return extracted_data


def retrieve_s3_keys(s3_client, time_filter=None):

    keys_to_process = []

    for s3_obj in s3_client.list_objects(Bucket=DEFAULT_BUCKET)['Contents']:
        keys_to_process.append(s3_obj['Key'])

    if time_filter:
        from_date = time_filter['from']
        to_date = time_filter['to']
        # TODO: implement

    return keys_to_process


def main():
    logger.info('Pulling data from Strava, reading input params..')

    '''arg_parser = argparse.ArgumentParser()
    arg_parser.add_argument('-t', '--accesstoken', dest='access_token')
    arg_parser.add_argument('-a', '--afterts', dest='after_timestamp')
    arg_parser.add_argument('-b', '--beforets', dest='before_timestamp')

    args = arg_parser.parse_args()

    access_token = args.access_token
    after_timestamp = args.after_timestamp
    before_timestamp = args.before_timestamp'''

    try:
        logger.info('Initializing S3 client')
        aws_region = os.environ.get('REGION') if not os.environ.get('REGION') else DEFAULT_REGION
        s3_client = boto3.client('s3', region_name=aws_region)
        logger.info('s3 client initialised successfully')

        logger.info('Loading config to extract data')
        with open(os.path.join('config', 'data_converter_config.json')) as conf:
            json_conf = json.load(conf)
            activity_keys = set(json_conf['wanted_keys'])
            header = json_conf['table_cols']

        logger.info('Config loaded successfully')
        logger.info('Retrieving files stored in S3')

        keys_to_process = retrieve_s3_keys(s3_client)
        logger.info(f'{len(keys_to_process)} activities to process')

        with open(os.path.join('data', 'merged_activities.csv'), mode='w', encoding='utf-8') as merged_activities:
            merged_csv_writer = csv.writer(merged_activities, delimiter=',', quotechar="'", quoting=csv.QUOTE_MINIMAL)
            merged_csv_writer.writerow(header)

            for s3_key in keys_to_process:
                logger.info(f'Processing {s3_key}')
                extracted_data = extract_data(s3_client, activity_keys, s3_key)
                merged_csv_writer.writerow(extracted_data)

        logger.info("Data extracted in data/merged_activities.csv")

    except Exception as e:
        logger.exception('Something went wrong whilst processing data')


main()