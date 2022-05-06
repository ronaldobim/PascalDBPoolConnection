# PascalDBPoolConnection
Generic Database Connection Pooling for Delphi/Lazarus/FreePascal

# Why use a connection pool?
Using connection pooling on application servers increases application performance. Avoiding connections at all times.

# Functionalities
* Compatibility with Delphi XE7(Up) and Lazarus(Last version).
* Simple and secure, just request connections to the pool. connections are returned to the pool automatically using reference counting.
* Fully Thread-Safe, test project included to perform stress testing.
* Works with any type of database access component because it does not use dependency on them (Zeos, Unidac, FireDac, etc.), the dependency is only with your application.
* Multitenant Control.
* Flexible to use with any development framework (Datanap, Horse, RDW, etc).
