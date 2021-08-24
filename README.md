Performance test gatling
========================

Performance test toolbox with Gatling for EPFL-SI web applications

Install
-------

```bash
git clone https://github.com/epfl-si/performance-test-gatling.git
cd performance-test-gatling
./bin/install.sh
```

Run
---

Default simulation:

```bash
./gatling/bin/gatling.sh
```

EPFL-SI simulation:

```bash
./gatling/bin/gatling.sh -sf simulations/
```

EPFL-SI cluster simulation with gathering of results:

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

(c) ECOLE POLYTECHNIQUE FEDERALE DE LAUSANNE, Switzerland, 2018-2021.

See the [LICENSE](LICENSE) file for more details.
