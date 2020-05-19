#!/usr/bin/env python3

import signal
import tornado.ioloop
import tornado.web
import unittest

PORT = 8888

class DummyTest(unittest.TestCase):
    def test_it(self):
        pass

    
class MainHandler(tornado.web.RequestHandler):
    def get(self):
        self.write("Hello, world\n")


class StatusHandler(tornado.web.RequestHandler):
    def get(self):
        self.write("healthy")


def make_app():
    return tornado.web.Application([
        (r"/", MainHandler),
        (r"/status", StatusHandler)
    ])


def main():
    app = make_app()
    server = app.listen(PORT)
    ioloop = tornado.ioloop.IOLoop.current()

    def stop():
        # Stop listening for more connections, and deregister
        # from the ioloop.
        server.stop()
        # Stop the ioloop.  Running tasks may still fining.
        ioloop.stop()

    def handler(_signum, _stack_frame):
        # Tell the ioloop to run the stop action.  IO loops are
        # not very thread safe, and we can't run the stop()
        # method in the signal handler.
        ioloop.add_callback_from_signal(stop)

    signal.signal(signal.SIGHUP, handler)
    signal.signal(signal.SIGTERM, handler)

    print('listening on port', PORT)
    ioloop.start()
    print('server stopped')


if __name__ == "__main__":
    main()
