// Copyright © 2017 s4cha. All rights reserved.

import Foundation

public typealias EmptyPromise = Promise<Void>
public typealias Async<T> = Promise<T>
public typealias AsyncTask = Async<Void>
