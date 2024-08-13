#!/bin/bash

      export LC_ALL=en_US.UTF-8
      export LANG=en_US.UTF-8
      export LANGUAGE=en_US.UTF-8
  
      echo "AC_METADATA_LOCALIZATION_LIST : $AC_METADATA_LOCALIZATION_LIST";
      echo "AC_SCREEN_SHOT_LIST : $AC_SCREEN_SHOT_LIST";
      echo "AC_FASTFILE_CONFIG : $AC_FASTFILE_CONFIG";
      echo "AC_APP_FILE_CONFIG : $AC_APP_FILE_CONFIG";

download_screenshots() {

      local json_file="$1"
      local continueDownload="true"; 


      if [[ ! -s "$json_file" ]] || ! jq -e '.[]' "$json_file" > /dev/null 2>&1; then
        echo "Error: Screenshot list file '$json_file' is empty or not a valid JSON array!" >&2
        continueDownload="false";
      fi

        counter=1

        for entry in $(jq -c '.[]' "$json_file"); do
            local signed_url=$(echo "$entry" | jq -r '.signedUrl')
            local lang=$(echo "$entry" | jq -r '.lang')
            local display_type=$(echo "$entry" | jq -r '.screenshotDisplayType')
            local order=$(echo "$entry" | jq -r '.order')
            local filename=$(basename "$signed_url" | cut -d'?' -f1)
            local extension="${filename##*.}"  # Get the file extension
            new_filename="${counter}_${lang}_${display_type}_${order}.${extension}"
            target_dir="./fastlane/metadata/android/$lang/images/$display_type"

            if [[ "$display_type" == "featureGraphic" ]] || [[ "$display_type" == "icon" ]] || [[ "$display_type" == "tvBanner" ]] ; then
              new_filename="${display_type}.${extension}"
              target_dir="./fastlane/metadata/android/$lang/images"
            fi

            if [[ ! -d "$target_dir" ]]; then
                mkdir -p "$target_dir"
            fi
        
            ((counter++))

            curl -o "$target_dir/$new_filename" -k "$signed_url"
            echo "Downloaded screenshot: $new_filename to $target_dir"
        done
}

if [[ -f "$AC_METADATA_LOCALIZATION_LIST" && -s "$AC_METADATA_LOCALIZATION_LIST" ]]; then

    jq -c '.[]' "$AC_METADATA_LOCALIZATION_LIST" | while IFS= read -r entry; do

        language_code=$(echo "$entry" | jq -r '.lang')
        metadata=$(echo "$entry")

        target_dir="./fastlane/metadata/android/$language_code"
        
        if [[ ! -d "$target_dir" ]]; then
            mkdir -p "$target_dir"
        fi

        title=$(echo "$metadata" | jq -r '.title')
        short_description=$(echo "$metadata" | jq -r '.shortDescription')
        full_description=$(echo "$metadata" | jq -r '.fullDescription')
        video=$(echo "$metadata" | jq -r '.video')

        echo "$title" > "./fastlane/metadata/android/$language_code/title.txt"
        echo "$short_description" > "./fastlane/metadata/android/$language_code/short_description.txt"
        echo "$full_description" > "./fastlane/metadata/android/$language_code/full_description.txt"
   

        if [ "$video" != "null" ]; then
            echo "$video" > "./fastlane/metadata/android/$language_code/video.txt"
        fi

    done
fi

     download_screenshots "$AC_SCREEN_SHOT_LIST"

     bundle init
     echo "gem \"fastlane\"">>Gemfile
     bundle install
     mkdir fastlane
     touch fastlane/Appfile
     touch fastlane/Fastfile
     mv "$AC_FASTFILE_CONFIG" "fastlane/Fastfile"
     mv "$AC_APP_FILE_CONFIG" "fastlane/Appfile"
     mv "$AC_API_KEY" "$AC_API_KEY_FILE_NAME"
     
     bundle exec fastlane update_metadata --verbose
     if [ $? -eq 0 ] 
       then
         echo "Metadata progress succeeded"
         exit 0
       else
         echo "Metadata progress failed :" >&2
         exit 1
       fi
