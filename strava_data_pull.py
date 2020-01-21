import os
import sys
import json
import argparse
import logging
import boto3
# from stravalib.client import Client
import requests
from datetime import datetime

FORMAT = '%(funcName)1s - # %(lineno)s - %(message)s'
logging.basicConfig(format=FORMAT)
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

DEFAULT_BUCKET = 'strava-feedme'
AWS_REGION = os.environ['REGION']
ACCESS_TOKEN = os.environ['ACCESS_TOKEN']
ACTIVITIES = 'ACTIVITIES'
LAP = 'LAP'
BASE_URL = 'https://www.strava.com/api/v3'

s3_client = boto3.client('s3', region_name=AWS_REGION)


def convert_ts_to_epoch(ts_to_convert):
    dt_ts = datetime.strptime(ts_to_convert,"%Y%m%d")
    epoch_ts = str(dt_ts.timestamp()).split(".")[0]

    return epoch_ts


def list_activities(before_timestamp=None, after_timestamp=None, access_token=None):

    timestamp_filter = ''
    if before_timestamp and after_timestamp:
        timestamp_filter = f'before={convert_ts_to_epoch(before_timestamp)}&after={convert_ts_to_epoch(after_timestamp)}'
    elif before_timestamp:
        timestamp_filter = f'before={convert_ts_to_epoch(before_timestamp)}'
    elif after_timestamp:
        timestamp_filter = f'after={convert_ts_to_epoch(after_timestamp)}'

    logger.info(f'Listing activities between in [ {before_timestamp}, {after_timestamp} ]')
    logger.info(f'{convert_ts_to_epoch(after_timestamp)}, {convert_ts_to_epoch(before_timestamp)}')

    activities_url = f'{BASE_URL}/athlete/activities?access_token={access_token}&{timestamp_filter}&per_page=200'
    logger.info(f'{activities_url}')

    response = requests.get(activities_url)
    response.raise_for_status()
    json_response = response.json()

    logger.info(f'# {len(json_response)} activities retrieved')

    return json_response


def get_activity(activity_id, access_token=None):

    logger.info(f'Getting detailed activity for {activity_id}')

    activity_url = f'{BASE_URL}/activities/{activity_id}?access_token={access_token}'

    response = requests.get(activity_url)
    response.raise_for_status()
    json_response = response.json()

    logger.info(f'# activity {activity_id} retrieved')

    return json_response


# This could be turned into a Lambda function, triggered daily as a cron job
def main():
    logger.info('Pulling data from Strava, reading input params..')

    arg_parser = argparse.ArgumentParser()
    arg_parser.add_argument('-t', '--accesstoken', dest='access_token')
    arg_parser.add_argument('-a', '--afterts', dest='after_timestamp')
    arg_parser.add_argument('-b', '--beforets', dest='before_timestamp')

    args = arg_parser.parse_args()

    access_token = args.access_token
    after_timestamp = args.after_timestamp
    before_timestamp = args.before_timestamp

    try:
        activities = list_activities(before_timestamp=before_timestamp, after_timestamp=after_timestamp,
                                     access_token=access_token)
        activity_ids = [item['id'] for item in activities]

        for activity_id in activity_ids:
            # getting activity info
            detailed_activity = get_activity(activity_id, access_token=access_token)
            activity_type = detailed_activity['type']
            day = detailed_activity['start_date_local']
            athlete_id = detailed_activity['athlete']['id']
            parsed_day = day.split('T')[0].replace('-', '')
            s3_key = f'athlete={athlete_id}/entity={ACTIVITIES}/type={activity_type}/day={parsed_day}/{activity_id}.json'
            logger.info(f'Storing activity data to s3 at {s3_key}')
            s3_client.put_object(Bucket=DEFAULT_BUCKET, Key=s3_key, Body=json.dumps(detailed_activity))

    except Exception as e:
        logger.exception(f'Something went wrong while processing data {e.__str__()}')


if __name__ == '__main__':
    main()
