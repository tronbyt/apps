"""Offline logic checks for the Python-compatible subset of this Starlark app.

These are NOT Pixlet renderer or Starlark interpreter tests. Run pixlet check
and both demo renders before submitting upstream.
"""
import copy
import json
from pathlib import Path
from types import SimpleNamespace
import unittest

SOURCE = Path(__file__).resolve().parents[1] / 'apps/zabbixproblems/zabbix_problems.star'

class Config(dict):
    pass

class Widgets:
    def __getattr__(self, name):
        return lambda **kwargs: dict(widget=name, **kwargs)

class Http:
    def __init__(self, replies):
        self.replies = iter(replies)
        self.calls = []

    def post(self, **kwargs):
        self.calls.append(copy.deepcopy(kwargs))
        status, data = next(self.replies)
        raw = data if isinstance(data, str) else json.dumps(data)
        return SimpleNamespace(status_code=status, body=lambda: raw, json=lambda: json.loads(raw))

def app(replies=(), big=False):
    http = Http(replies)
    env = dict(http=http, render=Widgets(), schema=Widgets(),
               canvas=SimpleNamespace(is2x=lambda: big, width=lambda: 128 if big else 64,
                                      height=lambda: 64 if big else 32),
               time=SimpleNamespace(now=lambda: SimpleNamespace(unix=100000)),
               type=lambda value: type(value).__name__)
    code = '\n'.join(line for line in SOURCE.read_text().splitlines() if not line.startswith('load('))
    exec(compile(code, str(SOURCE), 'exec'), env)
    return env, http

def ok(result):
    return 200, {'jsonrpc': '2.0', 'id': 1, 'result': result}

class Tests(unittest.TestCase):
    def test_url_and_filters(self):
        e, _ = app()
        self.assertEqual(e['endpoint']('https://example.com/zabbix/'), 'https://example.com/zabbix/api_jsonrpc.php')
        self.assertIsNone(e['endpoint']('http://example.com'))
        self.assertIsNone(e['endpoint']('https://user:password@example.com'))
        self.assertIsNone(e['endpoint']('https://example.com/?token=private'))
        p, error = e['filters'](Config(groupids='12, 34', unacknowledged_only='true'))
        self.assertIsNone(error)
        self.assertEqual(p['groupids'], ['12', '34'])
        self.assertEqual(p['severities'], [2, 3, 4, 5])
        self.assertFalse(p['recent'])
        self.assertFalse(p['acknowledged'])
        self.assertFalse(p['suppressed'])
        self.assertIsNotNone(e['filters'](Config(groupids='abc'))[1])

    def test_critical_before_newer_warning_and_host_join(self):
        problem = dict(objectid='42', eventid='10', name='Older critical event', severity='5', clock='1')
        e, h = app([ok('27'), ok([problem]), ok([dict(triggerid='42', hosts=[dict(name='database-01')])])])
        rows, count, error = e['fetch_problems'](Config(max_problems='1'), 'https://example.com/api_jsonrpc.php', 'test-only')
        self.assertIsNone(error)
        self.assertEqual(count, 27)
        self.assertEqual(rows[0]['host'], 'database-01')
        self.assertEqual(h.calls[1]['json_body']['params']['severities'], [5])
        self.assertEqual(h.calls[1]['json_body']['params']['sortfield'], ['eventid'])
        self.assertEqual(h.calls[2]['json_body']['method'], 'trigger.get')
        self.assertEqual(h.calls[0]['headers']['Authorization'], 'Bearer test-only')
        self.assertNotIn('auth', h.calls[0]['json_body'])

    def test_empty_is_success_only_with_valid_count(self):
        e, h = app([ok('0')])
        self.assertEqual(e['fetch_problems'](Config(), 'https://example.com', 'test'), ([], 0, None))
        self.assertEqual(len(h.calls), 1)

    def test_errors_are_not_healthy(self):
        for reply in [(403, {}), (429, {}), (500, {}), (200, '<html>SSO</html>'),
                      (200, {'error': {'data': 'private server details'}}), ok(None)]:
            e, _ = app([reply])
            rows, _, error = e['fetch_problems'](Config(), 'https://example.com', 'test')
            self.assertIsNone(rows)
            self.assertTrue(error)
            self.assertNotIn('private', error)

    def test_severity_buckets_until_page_limit(self):
        row = dict(objectid='1', name='Warning', severity='2', clock='1')
        e, h = app([ok('1'), ok([]), ok([]), ok([]), ok([row]), ok([])])
        rows, _, error = e['fetch_problems'](Config(), 'https://example.com', 'test')
        self.assertIsNone(error)
        self.assertEqual(rows[0]['host'], 'Host unavailable')
        self.assertEqual([c['json_body']['params']['severities'] for c in h.calls[1:5]], [[5], [4], [3], [2]])

    def test_demo_and_schema(self):
        for big in [False, True]:
            e, h = app(big=big)
            root = e['main'](Config(demo='true'))
            self.assertEqual(root['widget'], 'Root')
            self.assertEqual(len(root['child']['children']) * root['delay'], 12000)
            self.assertEqual(root['max_age'], 180)
            self.assertEqual(h.calls, [])
            fields = e['get_schema']()['fields']
            ids = [f['id'] for f in fields]
            self.assertEqual(len(ids), len(set(ids)))
            self.assertTrue(next(f for f in fields if f['id'] == 'token')['secret'])
            self.assertFalse(next(f for f in fields if f['id'] == 'demo')['default'])

    def test_age_and_limits(self):
        e, _ = app()
        self.assertEqual(e['age']('99999', 100000), '0m')
        self.assertEqual(e['age']('0', 100000), '1d')
        self.assertEqual(e['number'](Config(max_problems='1000'), 'max_problems', 3, 1, 3), 3)
        self.assertEqual(e['number'](Config(max_problems='bad'), 'max_problems', 3, 1, 3), 3)

if __name__ == '__main__':
    unittest.main()
