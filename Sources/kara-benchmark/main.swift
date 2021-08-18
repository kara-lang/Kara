import Benchmark

benchmark("add string reserved capacity") {
  var x: String = ""
  x.reserveCapacity(2000)
  for _ in 1...1000 {
    x += "hi"
  }
}

Benchmark.main()
