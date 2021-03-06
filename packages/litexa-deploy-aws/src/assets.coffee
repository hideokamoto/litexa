###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

AWS = require 'aws-sdk'
configureAWS = require './aws-config'

{
  collectUploadInfo
  listBucketAndUploadAssets
  prepareBucket
  validateS3BucketName
  validateS3PathName
} = require('./utils/s3Utils')

module.exports = {
  deploy: (context, logger) ->
    logger.log "deploying assets"
    skill = context.skill
    s3Context = null

    await configureAWS(context, logger, AWS)

    context.assetDeploymentStart = new Date

    unless context.deploymentOptions?.S3BucketName
      throw new Error "couldn't find `S3BucketName` in the '#{context.deploymentName}' deployment
        parameters from this project's config file. Please specify the bucket name you'd like to
        deploy to or create."

    bucketName = context.deploymentOptions.S3BucketName

    validateS3BucketName bucketName

    projectInfo = skill.projectInfo
    s3Context = {
      baseLocation: "#{projectInfo.name}/#{projectInfo.variant}"
      assets: {}
      listPage: 0
      bucketName: bucketName
    }

    validateS3PathName s3Context.baseLocation

    context.S3 = new AWS.S3 {
      params: {
        Bucket: bucketName
      }
    }

    region = context.S3.config.region
    s3Context.RESTRoot =  "https://s3.#{region}.amazonaws.com/#{bucketName}"
    context.artifacts.save 'assets-root', "#{s3Context.RESTRoot}/#{s3Context.baseLocation}/"

    us3UtilArgs = { s3Context, skillContext: context, logger }

    prepareBucket(us3UtilArgs)
    .then ->
      collectUploadInfo(us3UtilArgs)
    .then ->
      listBucketAndUploadAssets(us3UtilArgs)
    .catch (err) ->
      logger.error err
      throw "failed assets deployment"
}
