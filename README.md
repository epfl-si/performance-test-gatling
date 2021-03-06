Performance test gatling
========================

Performance test toolbox with Gatling for IDevelop web applications

Install
-------

```bash
git clone https://github.com/epfl-idevelop/performance-test-gatling.git
cd performance-test-gatling
./bin/install.sh
```

Run
---

Default simulation:

```bash
./gatling/bin/gatling.sh
```

IDevelop simulation:

```bash
./gatling/bin/gatling.sh -sf simulations/
```

IDevelop cluster simulation with gathering of results:

```bash
./bin/cluster-run.sh <simulation_name>
```
Example: `./bin/cluster-run.sh WwwProxy`

Developers
----------

  * [Olivier Bieler](https://github.com/obieler)
  * [William Belle](https://github.com/williambelle)

Documentation
-------------
  * [Gatling documentation](https://gatling.io/docs/current/)
  * For asking questions, join the [Google Group](https://groups.google.com/forum/#!forum/gatling).

License
-------

Apache License 2.0

(c) ECOLE POLYTECHNIQUE FEDERALE DE LAUSANNE, Switzerland, VPSI, 2018.

See the [LICENSE](LICENSE) file for more details.
