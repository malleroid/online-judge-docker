FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

WORKDIR /judge

# Install Leiningen and dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential ca-certificates leiningen wget zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Create Leiningen project
RUN lein new app main

# Download ac-library-java JAR
RUN mkdir -p main/lib \
    && wget -q -O main/lib/ac_library.jar https://github.com/ocha98/ac-library-java/releases/download/v2.0.0/ac_library21.jar

# Update project.clj with Clojure 1.12.2 and ac-library
RUN cd main \
    && sed -i -e 's@:dependencies \[.*@:dependencies \[\[org.clojure/clojure "1.12.2"\]\]\n  :resource-paths \["lib/ac_library.jar"\]@' project.clj

# Pre-build: resolve deps and test AOT compilation
RUN cd main \
    && printf '(ns main.core\n  (:gen-class))\n\n(defn -main\n  [& args]\n  (println "Hello"))\n' > src/main/core.clj \
    && lein do clean, uberjar \
    && lein clean

# Copy execution wrapper script
COPY clojure-aot.sh clojure-aot.sh
