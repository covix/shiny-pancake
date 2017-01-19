import json
import sys
import os
import pandas as pd
from bs4 import BeautifulSoup
import time
import datetime


def create_map_ds(tweets):
    new = []
    for tweet in tweets:
        if tweet['coordinates']:
            long_, lat = tweet['coordinates']['coordinates']
            source = BeautifulSoup(
                tweet['source'], "lxml").text.encode('utf-8')

            tw = {
                'id': tweet['id'],
                'long': long_,
                'lat': lat,
                'source': source,
                'created_at': tweet['created_at']
            }
            new.append(tw)

    new = pd.DataFrame(new)

    return new


def create_hs_ds(tweets):
    new = []
    for tweet in tweets:
        for hs in tweet['entities']['hashtags']:
            ts = time.strftime('%Y-%m-%d %H:00:00',
                               time.strptime(tweet['created_at'], '%a %b %d %H:%M:%S +0000 %Y'))

            ts = time.mktime(datetime.datetime.strptime(
                ts, "%Y-%m-%d %H:%M:%S").timetuple())

            tw = {
                'created_at': ts,
                'text': hs['text'].encode('utf-8')
            }
            new.append(tw)

    new = pd.DataFrame(new)

    return new


def main():
    # ds = '../data/tweets_macbook_sample.txt'
    ds = sys.argv[1]
    cmd = sys.argv[2]
    fname, ext = os.path.splitext(ds)

    with open(ds) as f:
        tweets = [json.loads(i) for i in f]

    functions = {
        'hs': create_hs_ds,
        'map': create_map_ds
    }

    df = functions[cmd](tweets)
    df.to_csv("{0}_{1}{2}".format(fname, cmd, ext), index=False)

    # df_hs = create_hs_ds(tweets)
    # df_hs.to_csv("{0}_hs{1}".format(fname, ext), index=False)


if __name__ == '__main__':
    main()
