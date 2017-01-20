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
                'created_at': tweet['created_at'],
                'text': ' '.join(tweet['text'].split()),
                'user': tweet['user']['screen_name'],
            }
            new.append(tw)

    new = pd.DataFrame(new)
    new['id'] = new['id'].astype(str)

    return new


def create_hs_ds(tweets):
    new = []
    for tweet in tweets:
        for hs in tweet['entities']['hashtags']:
            ts = time.strftime('%Y-%m-%d %H:00:00',
                               time.strptime(tweet['created_at'], '%a %b %d %H:%M:%S +0000 %Y'))

            ts = time.mktime(datetime.datetime.strptime(
                ts, "%Y-%m-%d %H:%M:%S").timetuple())
            user = tweet['retweeted_status'][
                'user'] if 'retweeted_status' in tweet else tweet['user']

            tw = {
                'created_at': ts,
                'text': hs['text'].encode('utf-8'),
                'screen_name': user['screen_name']
            }
            new.append(tw)

    new = pd.DataFrame(new)

    return new


def create_nodes_ds(tweets):
    new = {}

    for tweet in tweets:
        sc = tweet['user']['screen_name']
        if sc not in new:
            new[sc] = {
                'idx': len(new),
                'name': tweet['user']['screen_name'],
                'size': 1
            }
        else:
            new[sc]['size'] = new[sc]['size'] + 1

    new = pd.DataFrame(new.values())

    new = new[new['size'] > 0]

    return new


def create_links_ds(tweets):
    nodes = create_nodes_ds(tweets)
    nodes.to_csv("{0}_{1}{2}".format(fname, 'nodes', ext),
                 index=False, encoding='utf-8')
    new = {}
    names = dict(nodes[['name', 'idx']].values)

    for tweet in tweets:
        if 'retweeted_status' in tweet:
            if tweet['user']['screen_name'] in names and tweet['retweeted_status']['user']['screen_name'] in names:
                k = (
                    names[tweet['user']['screen_name']],
                    names[tweet['retweeted_status']['user']['screen_name']]
                )

                if k not in new:
                    new[k] = {
                        'source': names[tweet['user']['screen_name']],
                        'target': names[tweet['retweeted_status']['user']['screen_name']],
                        'size': 1
                    }
                else:
                    new[k]['size'] = new[k]['size'] + 1

    new = pd.DataFrame(new.values())

    return new


def create_sources_ds(tweets):
    new = {}
    for tweet in tweets:
        source = BeautifulSoup(tweet['source'], "lxml").text
        new[source] = new.get(source, 0) + 1

    new = pd.DataFrame(new.items(), columns=['source', 'count'])

    return new


def main():
    with open(ds) as f:
        tweets = [json.loads(i) for i in f]

    # functions = {
    #     'hs': create_hs_ds,
    #     'map': create_map_ds,
    #     'node': create_node_ds,
    # }

    for cmd in cmds:
        df = sys.modules[__name__].__dict__['create_{}_ds'.format(cmd)](tweets)
        df.to_csv("{0}_{1}{2}".format(fname, cmd, ext),
                  index=False, encoding='utf-8')

if __name__ == '__main__':
    # ds = '../data/tweets_macbook_sample.txt'
    ds = sys.argv[1]
    cmds = sys.argv[2:]
    fname, ext = os.path.splitext(ds)

    main()
