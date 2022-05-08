## To build for multiple cpu architect:

### Install qemu to create the emulator for building

```bash
apt-get install qemu qemu-user-static binfmt-support debootstrap -y
```

### Create custom builder

```bash
docker buildx create --name armBuilder
```

### User new custom builder

```bash
docker buildx use armBuilder
```

### Bulid and push new image for multi platform

```bash
sudo docker buildx build --platform linux/amd64,linux/arm64/v8,linux/arm/v7 -t sontl/frontend-node:latest --push .
```

### Using script to build and push to docker hub, rembmer to update DOCKER_PASSWORD before running

```bash
bash scripts/build-push.sh
```

## Supported tags and respective `Dockerfile` links

- [`14`, `16`, `17`, _(Dockerfile)_](https://github.com/greenaj/node-frontend/blob/master/Dockerfile)

# Node.js frontend development with Chrome Headless tests

This Docker image is forked from [tiangolo/node-frontend](https://github.com/tiangolo/node-frontend), for more about the original author see [tiangolo (Sebastián Ramírez)](https://github.com/tiangolo).

This Docker image simplifies the process of creating a full Node.js environment for frontend development with multistage building.

The main aspects about this project from the original project:

- Puppeteer is not installed, just its dependencies. Install puppeteer in your Node project.
- The version of Node.js is updated to keep pace with the latest stable (LTS) version released.
- The default.conf file is updated to keep pace with the docker container released for latest stable version of NGINX [nginx - Docker Hub](https://hub.docker.com/_/nginx).

The main similaries from the original project:

- Includes a default Nginx configuration for your frontend application, in multi-stage Docker builds you can copy it to an Ngnix "stage". In this version, it keeps the original name `default.conf`. The orinal project used `nginx.conf` foir the file name though.

## Articles From Previous Author

> Angular in Docker with Nginx, supporting configurations / environments, built with multi-stage Docker builds and testing with Chrome Headless

[in Medium](https://medium.com/@tiangolo/angular-in-docker-with-nginx-supporting-environments-built-with-multi-stage-docker-builds-bb9f1724e984), and [in GitHub](https://github.com/tiangolo/medium-posts/tree/master/angular-in-docker)

## How to use

_Most of the documentation below comes from the original project, being created by the original author:_

### Previous steps

- Create your frontend Node.js based code (Angular, React, Vue.js).

- Create a file `.dockerignore` (similar to `.gitignore`) and include in it:

```
node_modules
```

...to avoid copying your `node_modules` to Docker, making things unnecessarily slower.

- If you want to integrate testing as part of your frontend build inside your Docker image building process (using Chrome Headless via Puppeteer), install Puppeteer locally, so that you can test it locally too and to have it in your development dependencies in your `package.json`:

```bash
npm install --save-dev puppeteer
```

### Dockerfile

- Create a file `Dockerfile` based on this image and name the stage `build-stage`, for building:

```Dockerfile
# Stage 0, "build-stage", based on Node.js, to build and compile the frontend
FROM greenaj/node-frontend:12 as build-stage

...

```

- Copy your `package.json` and possibly your `package-lock.json`:

```Dockerfile
...

WORKDIR /app

COPY package*.json /app/

...
```

...just the `package*.json` files to install all the dependencies once and let Docker use the cache for the next builds. Instead of installing everything after every change in your source code.

- Install `npm` packages inside your `Dockerfile`:

```Dockerfile
...

RUN npm install

...
```

- Copy your source code, it can be TypeScript files, `.vue` or React with JSX, it will be compiled inside Docker:

```Dockerfile
...

COPY ./ /app/

...
```

- If you have integrated testing with Chrome Headless using Puppeteer, this image comes with all the dependencies for Puppeteer, so, after installing your dependencies (including `puppeteer` itself), you can just run it. E.g.:

```Dockerfile
...

RUN npm run test -- --browsers ChromeHeadlessNoSandbox --watch=false

...
```

...if your tests didn't pass, they will throw an error and your build will stop. So, you will never ship a "broken" frontend Docker image to production.

- If you need to pass buildtime arguments, for example in Angular, for `--configuration`s, create a default `ARG` to be used at build time:

```Dockerfile
...

ARG configuration=production

...
```

- Build your source frontend app as you normally would, with `npm`:

```Dockerfile
...

RUN npm run build

...
```

- If you need to pass build time arguments (for example in Angular), modify the previous instruction using the previously declared `ARG`, e.g.:

```Dockerfile
...

RUN npm run build -- --output-path=./dist/out --configuration $configuration

...
```

...after that, you would have a fresh build of your frontend app code inside a Docker container. But if you are serving frontend (static files) you could serve them with a high performance server as Nginx, and have a leaner Docker image without all the Node.js code.

- Create a new "stage" (just as if it was another Docker image in the same file) based on Nginx:

```Dockerfile
...

# Stage 1, based on Nginx, to have only the compiled app, ready for production with Nginx.
# You may wish to adjust the tag for the version of NGINX though.
FROM nginx:1.16

...
```

- Now you will use the `build-stage` name created above in the previous "stage", copy the files generated there to the directory that Nginx uses:

```Dockerfile
...

COPY --from=build-stage /app/dist/out/ /usr/share/nginx/html

...
```

... make sure you change `/app/dist/out/` to the directory inside `/app/` that contains your compiled frontend code.

- This image also contains a default Nginx configuration so that you don't have to provide one. By default it routes everything to your frontend app (to your `index.html`), so that you can use "HTML5" full URLs and they will always work, even if your users type them directly in the browser. Make your Docker image copy that default configuration from the previous stage to Nginx's configurations directory:

```Dockerfile
...

COPY --from=build-stage /default.conf /etc/nginx/conf.d/default.conf

...
```

- Your final `Dockerfile` could look like:

```Dockerfile
# Stage 0, "build-stage", based on Node.js, to build and compile the frontend
FROM greenaj/node-frontend:12 as build-stage

WORKDIR /app

COPY package*.json /app/

RUN npm install

COPY ./ /app/

RUN npm run test -- --browsers ChromeHeadlessNoSandbox --watch=false

ARG configuration=production

RUN npm run build -- --output-path=./dist/out --configuration $configuration


# Stage 1, based on Nginx, to have only the compiled app, ready for production with Nginx
FROM nginx:1.16

COPY --from=build-stage /app/dist/out/ /usr/share/nginx/html

COPY --from=build-stage /default.conf /etc/nginx/conf.d/default.conf
```

### Building the Docker image

- To build your shiny new image run:

```bash
docker build -t my-frontend-project:prod .
```

...If you had tests and added above, they will be run. Your app will be compiled and you will end up with a lean high performance Nginx server with your fresh compiled app. Ready for production.

- If you need to pass build time arguments (like for Angular `--configuration`s), for example if you have a "staging" environment, you can pass them like:

```bash
docker build -t my-frontend-project:stag --build-arg configuration="staging" .
```

### Testing the Docker image

- Now, to test it, run:

```bash
docker run -p 80:80 my-frontend-project:prod
```

...if you are running Docker locally you can now go to `http://localhost` in your browser and see your frontend.

## Tips

- Develop locally, if you have a live reload server that runs with something like:

```bash
npm run start
```

...use it.

It's faster and simpler to develop locally. But once you think you got it, build your Docker image and try it. You will see how it looks in the full production environment.

- If you want to have Chrome Headless tests, run them locally first, as you normally would (Karma, Jasmine, Jest, etc). Using the live normal browser. Make sure you have all the configurations right. Then install git peteer locally and make sure it runs locally (with local Headless Chrome). Once you know it is running locally, you can add that to your `Dockerfile` and have "continuous integration" and "continuous building"... and if you want add "continuous deployment". But first make it run locally, it's easier to debug only one step at a time.

- Have fun.

## Advanced Nginx configuration

You can include more Nginx configurations by copying them to `/etc/nginx/conf.d/`, beside the included Nginx configuration.

## License

This project is licensed under the terms of the MIT license.
