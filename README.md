# UniversalBluetooth for macOS

_UniversalBluetooth_ is a communication library built on top of [CoreBluetooth](https://developer.apple.com/reference/corebluetooth). It provides an easy way of sending/receiving objects (aka NSDictionary) between two devices.

## How does it work?

Initialize and start scanning:

```
UniversalBluetooth * universal = [[UniversalBluetooth alloc] init];
universal.delegate = self;

[universal start];
```

Implement the delegate method, required to receive objects:

```
- (void)UniversalBluetooth:(UniversalBluetooth *)UniversalBluetooth didReceiveObject:(NSDictionary *)object
{
  // Handle the received object here...
}
```

Send objects:

```
[universal sendObject:@{ @"message": @"hello" }];
```

The two devices will connect immediately when they are close to each other (~0.5m or less).

Please have a look at the __Start Example__ (located in /examples/start-example) and try it for yourself.

## Any future plans?

Yes. The library is _quite basic_ right now. Here's what's in my head:

* Implement message framing (in order to overcame a low MTU)
* Support more than 2 devices per session
* Add support for Swift
* Pub/Sub
* Improve the library interface
* Improve the project documentation
* Include more examples (ie. games)
* Support other platforms/languages (ie. Android, Intel edison, Beaglebone)
