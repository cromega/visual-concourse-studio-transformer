# visual-concourse-studio-transformer
transforms node-red json to concourse pipeline yaml. sort of.

## Usage

1. Use [this fork](https://github.com/winnab/node-red) of node-red as the Studio UI. We didn't have time to create more node
 types with the right attributes. Use the node called "resource" for anything that is not "git" or "s3".

2. Once you finish putting together a flow, select all the nodes and export it as JSON from the top-right menu and stick it in a file

3. Create the pipeline YAML

```
ruby transform.rb exported.json > pipeline.yml
```

4. Set the pipeline

```
fly set-pipeline -p pipeline -c pipeline.yml
```

5. ???????

6. PROFIT

### Note on job config lookup

Job nodes can take a YAML as configuration body that contains the list of tasks and the extra params to be passed on to the input and output resources

example:

```yaml
tasks:
  sometask: somefile.yml
someresource:
  get: # will be passed on as params to the input resource "someresource"
    someparam: somevalue
  put: # will be passed on as params to the output resource "someresource"
    someparam: somevalue
```

## Issues
1. lots of missing attribute extraction all over the place
2. Job configuration handling is very basic
3. most likely broken dependency lookup
4. No trigger config
5. No way of specifying a resource once and then plugging it into various jobs. node-red just doesn't work that way.




