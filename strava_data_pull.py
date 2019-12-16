import os
import sys
import json
import argparse
import logging
import boto3

FORMAT = '%(funcName)1s - # %(lineno)s - %(message)s'
logging.basicConfig(format=FORMAT)
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

DEFAULT_BUCKET = 'strava-feedme'
AWS_REGION = os.environ['REGION']
ACTIVITIES = 'ACTIVITIES'
LAP = 'LAP'

s3_client = boto3.client('s3', region_name=AWS_REGION)


def list_activities(access_token, after_timestamp):
    logger.info(f'Listing activities after {after_timestamp}')
    activities = []

    # TODO: implement

    logger.info(f'{len(activities)} have been retrieved')

    return activities


def get_activity(activity_id):
    logger.info(f'Getting detailed activity for {activity_id}')
    detailed_activity = {}

    # TODO: implement

    return detailed_activity

# This could be turned into a Lambda function, triggered daily as a cron job

def main():
    logger.info('Pulling data from Strava, reading input params..')

    arg_parser = argparse.ArgumentParser()
    arg_parser.add_argument('-t', '--accesstoken', dest='access_token')
    arg_parser.add_argument('-a', '--afterts', dest='after_timestamp')

    args = arg_parser.parse_args()

    access_token = args.access_token
    after_timestamp = args.after_timestamp

    try:
        activities = list_activities(access_token, after_timestamp)
        activity_ids = []  # TODO implement list comprenshion from activities to extract activities id

        for activity_id in activity_ids:
            # getting activity info
            detailed_activity = get_activity(activity_id)
            activity_type = detailed_activity['type']
            day = detailed_activity['start_date_local']
            athlete_id = detailed_activity['athlete']['id']
            parsed_day = ''  # TODO: needs parsing
            s3_key = f'a={athlete_id}/e={ACTIVITIES}/t={activity_type}/d={parsed_day}/{activity_id}.json'
            logger.info(f'Storing activity data to s3 at {s3_key}')
            s3_client.put_object(Bucket=DEFAULT_BUCKET, Key=s3_key, Body=detailed_activity)

    except Exception as e:
        logger.exception(f'Something went wrong while processing data {e.__str__()}')


if __name__ == '__main__':
    main()
