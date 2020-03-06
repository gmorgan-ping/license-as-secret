#!/usr/bin/env sh
#
# Ping Identity DevOps - Docker Build Hooks
#
#- Check for license file
#- - If in SERVER_ROOT_DIR, good
#- - If PING_IDENTITY_DEVOPS_USER and PING_IDENTITY_DEVOPS_KEY
#- provided then pull eval license from license server
#
#  TODO - Should probably add more mechanisms to pull from other
#         locations (i.e. vaults/secrets)
#
${VERBOSE} && set -x

# shellcheck source=pingcommon.lib.sh
. "${HOOKS_DIR}/pingcommon.lib.sh"

LICENSE_FILE="${LICENSE_DIR}/${LICENSE_FILE_NAME}"

sleep(200000)
if test -f "${LICENSE_FILE}" ; then
   licenseFound="true"
else
   if test ! -z "${PING_IDENTITY_DEVOPS_USER}" && test ! -z "${PING_IDENTITY_DEVOPS_KEY}" ; then
        ##################################################################
        # Let's get the license from the license server
        ##################################################################
        if ! test -z "${LICENSE_SHORT_NAME}" && ! test -z "${LICENSE_VERSION}" ; then
            echo "Pulling evaluation license from Ping Identity for:
              Prod License: ${LICENSE_SHORT_NAME} - v${LICENSE_VERSION} 
               DevOps User: ${PING_IDENTITY_DEVOPS_USER}..."
        
            licenseCurlResult=$( curl -kL -w '%{http_code}' -G \
                -H "product: ${LICENSE_SHORT_NAME}" \
                -H "version: ${LICENSE_VERSION}" \
                -H "devops-user: ${PING_IDENTITY_DEVOPS_USER}" \
                -H "devops-key: ${PING_IDENTITY_DEVOPS_KEY}" \
                -H "devops-app: ${IMAGE_VERSION}" \
                "https://license.pingidentity.com/devops/v2/license" \
                -o "${LICENSE_FILE}" 2> /dev/null )
            #
            # Just testing the http code isn't sufficient, curl will return http 200 if it
            # can retrieve the file even if it can't actually write the file to disk. We
            # also need to capture & test the curl return code.
            #
            rc=${?}
            if test $licenseCurlResult -eq 200 && test ${rc} -eq 0 ; then
                echo "Successfully pulled evaluation license from Ping Identity"
                test "${PING_DEBUG}" = "true" && cat_indent "${LICENSE_FILE}"
                echo ""

                case "${PING_IDENTITY_ACCEPT_EULA}" in
                    YES|yes|Y|y)
                        ;;
                    *)
                    container_failure 17 "You must accept the EULA by providing the environment variable PING_IDENTITY_ACCEPT_EULA=YES"
                    ;;
                esac

                licenseFound="true"
            else
                echo "Unable to download evaluation product.lic (${licenseCurlResult}), most likely due to invalid PING_IDENTITY_DEVOPS_USER/PING_IDENTITY_DEVOPS_KEY"
                rm -f "${LICENSE_FILE}"
            fi
        else
            echo "Unable to determine LICENSE_SHORT_NAME (${LICENSE_SHORT_NAME}) or LICENSE_VERSION (${LICENSE_VERSION})"
        fi
    fi
fi

if test ! "${licenseFound}" = "true" ; then
    echo_red "
##################################################################################
############################        ALERT        #################################
##################################################################################
# 
# No Ping Identity License File (${LICENSE_FILE_NAME}) was found in the server profile.
# No Ping Identity DevOps User or Key was passed.  
# 
# 
# More info on obtaining your DevOps User and Key can be found at:
#      https://pingidentity-devops.gitbook.io/devops/prod-license
# 
##################################################################################"
    container_failure 17 "License File absent"
fi
