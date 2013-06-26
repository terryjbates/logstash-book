#!/bin/sh -

sudo curl -s -XPUT http://127.0.0.1:9200/_template/logstash_per_index -d '{
    "template": "logstash*",
    "settings": {
        "index.query.default_field": "@message",
        "index.cache.field.type": "soft",
        "index.store.compress.stored": true
    },
    "mappings": {
        "_default_": {
            "_all": {
                "enabled": false
            },
            "properties": {
                "@message": {
                    "type": "string",
                    "index": "analyzed"
                },
                "@source": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "@source_host": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "@source_path": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "@tags": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "@timestamp": {
                    "type": "date",
                    "index": "not_analyzed"
                },
                "@type": {
                    "type": "string",
                    "index": "not_analyzed"
                }
            }
        }
    }
}
'