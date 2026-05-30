---
title: "오디오파일 ETL의 자동화"
---

# 오디오파일 ETL의 자동화

Status: Not started

[https://www.youtube.com/watch?v=k0hGlxSoqtY&t=74s](https://www.youtube.com/watch?v=k0hGlxSoqtY&t=74s)

큐앤에이소프트는 공식 홈페이지를 비롯해 수 십개의 매체를 통해 상담 접수를 받고 있습니다.  운영하는 매체가 다양한 만큼, 매체마다 접수되는 스팸의 양에 따른 퀄리티도 다양합니다. 각 매체의 퀄리티를 추산하기 위해 다양한 지표를 사용하고 있는데요, 이번 포스팅에 사용할 지표는 통화 시간입니다. 

고객이 상담폼에 적은 전화번호로 전화를 걸면, 일반적으로 스팸인 경우, 통화시간이 10초 이내입니다. 이에 따라 각 매체 별 접수된 상담의 통화시간-통화수 의 평균이 적을 수록, 그 매체의 퀄리티가 낮을 가능성이 높다고 가정합니다.

영업팀이 통화한 파일을 업로드, 통화시간-통화수를 구하기 까지의 절차는 다음과 같습니다.

1. t전화를 통해 녹취파일 자동 생성
2. driveSync를 통해 파일을 googleDrive에 자동 업로드
3. google apps script로 업로드된 파일명을 전처리, 파일 분류
4. 서버에서 google drive api로 전날 업로드된 파일을 다운로드
5. pydub의 AudioSegment를 사용해 통화시간 구하고 중앙서버에 저장

1,2의 과정은 개발관련이 아니라 생략하겠습니다.

1. google apps script에서 업로드된 파일명을 정리, 파일 분류
    
    apps script는 구글에서 제공하는 스크립팅 플랫폼입니다. 구글 드라이브, 구글 시트, 캘린더, gmail 등 다양한 구글앱에 접근 가능한 api를 지원하여 쉽게 사무 자동화를 할 수 있습니다. 언어는 JS를 사용하고 있고  ES6 전의 버전이라 최신 문법들은 지원되지 않습니다. 
    
    ![[attachments/오디오파일 ETL의 자동화_Untitled.png]]
    
    또한 트리거로 스크립트 실행 스케쥴러를 쉽게 생성할 수 있습니다. 물론 script에서 트리거를 삭제하는 메서드도 존재합니다.
    
    저희는 각 영업팀의 담당자의 폴더를 만들어 녹취파일을 업로드 하고 있습니다. t전화가 자동으로 생성하는 파일명은 [전화번호]_YYYYMMDDhhmmss.m4a입니다. 이 파일명을 정리하여
    
    manager
    
    ㄴ YYYY년_MM월
    
    ㄴ YYYY년_MM월_DD일
    
    폴더에 분류합니다.
    
    드라이브 api에는 파일을 폴더간 옮기는 메서드가 없기 때문에 현재 위치에서 삭제 → 옮길 폴더 위치에서 생성 과정을 거쳐야 합니다.
    
    ```jsx
    var startTime = 0;
    var currentTime = 0;
    const MAXIMUM_EXE_TIME = 3500;
    const EXE_TERM = 5;
    const FOLDER_ID = [];
    
    function categorizeCallRecs(){
      startTime = (new Date()).getTime() / 1000;
      currentTime = startTime;
      var prop = PropertiesService.getScriptProperties();
      var run = prop.getProperty('run');
      
      var errorList = new Array();  // 파일 이름 중 오류가 있어 분류하지 못한 파일 이름 배열
      for(let id  of FOLDER_ID){
        var pFolder = DriveApp.getFolderById(id);
        var targetFolder = {};
        
        var files = pFolder.getFiles();   // 분류할 모든 파일 리스트
        var file;
        
        while(files.hasNext())
        {
          file = files.next();
          var oName = file.getName();
      
          var name = oName.split('_')
          if (oName.includes('통화 녹음 ')){ //갤럭시 : 통화 녹음 [전화번호]_YYMMDD_hhmmss.m4a
            var name = oName.split('통화 녹음 ')[1].split('_'); // name[0] : 전화번호(이름) / name[1]:yymmdd / name[2]:hhmmss.m4a
            name[1] = '20'+name[1]+name[2]
          }
          else{
            var name = oName.split('_');    // t전화 : name[0] : 전화번호 / name[1] : 연월일시분초 YYYYMMDDhhmmss.m4a
          }
      
          var file_type = name[1].split('.')[1]
          
          if(!(file_type === 'm4a' | file_type === 'amr'))    // 기존의 이름 형식과 맞는지 확인하기 위함
          {
            console.log(`파일명 ${oName}은 잘못된 이름으로 보이므로 처리하지 않음(파일형식 = ${file_type}`);
            errorList[errorList.length] = oName;
            continue;
          }
          
          var date = {
            year: name[1].substring(0, 4),
            month: name[1].substring(4, 6),
            day: name[1].substring(6, 8),
            hour: name[1].substring(8, 10),
            minute: name[1].substring(10, 12),
            second: name[1].substring(12, 14)
          };
          var newName = `${date.year}_${date.month}_${date.day}_${date.hour}_${date.minute}_${date.second}_${name[0]}.${file_type}`;
    
          targetFolder[date.year] = {};
          targetFolder[date.year][date.month] = findFolderToPut(date,id,`${date.year}년_${date.month}월`);
          targetFolder[date.year][date.month][date.day] = findFolderToPut(date,targetFolder[date.year][date.month].getId(),`${date.year}년_${date.month}월_${date.day}일`)
          moveFile(file, targetFolder[date.year][date.month][date.day], targetFolder[date.year][date.month]);
          file.setName(newName);
          
          console.log(`파일명 ${newName} : 폴더명 ${targetFolder[date.year][date.month][date.day].getName()}`);
          currentTime = (new Date()).getTime() / 1000;
          if(currentTime - startTime > MAXIMUM_EXE_TIME)
          {
            prop.setProperty('run', 'continue');
            console.log('실행 시간 초과로 다음 실행으로 넘겨주고 종료');
            // deleteTriggers('categorizeCallRecs');
            ScriptApp.newTrigger('categorizeCallRecs')
            .timeBased()
            .after((1000*EXE_TERM))
            .create();
            if(errorList[0])
            {
              console.log('실행 중 오류로 분류하지 못한 파일이 있습니다. 아래 목록을 참고하세요.');
              for(var i=0; i<errorList.length; i++)
                console.log(`에러 ${parseInt(i)+1}. ${errorList[i]}`);
            }
            return;
          }
        }
      }
      prop.deleteProperty('run');
      // deleteTriggers('categorizeCallRecs');
      if(errorList[0])
      {
        console.log('실행 중 오류로 분류하지 못한 파일이 있습니다. 아래 목록을 참고하세요.');
        for(var i=0; i<errorList.length; i++)
          console.log(`에러 ${parseInt(i)+1}. ${errorList[i]}`);
      }
      console.log('모든 파일 분류 끝, 스크립트 종료');
      return;
    }
    
    function findFolderToPut(date,FOLDER_ID,folderName) {
      var pFolder = DriveApp.getFolderById(FOLDER_ID);
      var folder = DriveApp.searchFolders(`title = '${folderName}' and parents in '${FOLDER_ID}'`);
        
      if(folder.hasNext())
        return folder.next();
      else
        return pFolder.createFolder(folderName);
    }
    
    function moveFile(file, targetFolder, originalFolder)
    {
      targetFolder.addFile(file);
      originalFolder.removeFile(file);
    }
    
    function deleteTriggers(funcName)
    {
      var triggers = ScriptApp.getProjectTriggers();
      
      for(var i=0; i<triggers.length; i++)
        if(triggers[i].getHandlerFunction() == funcName)
          ScriptApp.deleteTrigger(triggers[i]);
      
      return;
    }
    ```
    
2. 서버에서 google drive api로 전날 업로드된 파일을 다운로드
'3번에서 파일 duration을 구하면 되는거 아닌가?' 라고 생각할 수 있지만, google drive에 올라와 있는 파일의 메타 데이터만 조회할 수 있기 때문에 duration을 구하기 위해선 구글드라이브에서 파일을 직접 내려 받아야 합니다. 
    
    따라서 google drive api를 사용했고 java, node.js, python, python codelab를 지원하고 있습니다.
    
    ```python
    from __future__ import print_function
    import pickle
    import os.path
    from googleapiclient.discovery import build
    from google_auth_oauthlib.flow import InstalledAppFlow
    from google.auth.transport.requests import Request
    from apiclient import errors
    import io
    from googleapiclient.http import MediaIoBaseDownload
    import requests
    
    SCOPES = ['https://www.googleapis.com/auth/drive']
    def main():
        creds = None
        if os.path.exists('token.pickle'):
            with open('token.pickle', 'rb') as token:
                creds = pickle.load(token)
        # If there are no (valid) credentials available, let the user log in.
        if not creds or not creds.valid:
            if creds and creds.expired and creds.refresh_token:
                creds.refresh(Request())
            else:
                flow = InstalledAppFlow.from_client_secrets_file(
                    './client_secret_.json', SCOPES)
                creds = flow.run_local_server(port=0)
            with open('token.pickle', 'wb') as token:
                pickle.dump(creds, token)
        service = build('drive', 'v3', credentials=creds)
        return service
        
    
    def download(service,folder_name,manager_name):
        try:
            manager_folder_id = search_query(service,folder_query(manager_name))[0][1]
            manager_month_folder_id = search_query(service,manager_folder_query(folder_name[:-4],manager_folder_id))[0][1]
        except:
            return
        folder_list = search_query(service,manager_folder_query(folder_name,manager_month_folder_id))
        os.makedirs(os.getcwd()+f"\\{manager_name}",exist_ok=True)
        os.chdir(os.getcwd()+f"\\{manager_name}")
        for folder_name, folder_id in folder_list:
            file_list = search_query(service,file_query(folder_id))
            for file_name, file_id in file_list:
                request = service.files().get_media(fileId=file_id)
                fh = io.FileIO(file_name, mode='wb')
                downloader = MediaIoBaseDownload(fh, request)
                done = False
                while done is False:
                    status, done = downloader.next_chunk()
                    print ("Download %d%%." % int(status.progress() * 100))
    
    file_query = lambda folder_id : f"mimeType != 'application/vnd.google-apps.folder' and '{folder_id}' in parents and trashed = false"
    folder_query = lambda folder_name : f"mimeType = 'application/vnd.google-apps.folder' and name = '{folder_name}' and trashed = false"
    manager_folder_query = lambda folder_name,manager_id : f"mimeType = 'application/vnd.google-apps.folder' and name = '{folder_name}' and '{manager_id}' in parents and trashed = false"
    
    def search_query(service,query):
        result = []
        page_token = None
        while True:
            response = service.files().list(q=query,
                                                spaces='drive',
                                                fields='nextPageToken, files(id, name)',
                                                pageToken=page_token).execute()
            for obj in response.get('files', []):
                # Process change
                result.append((obj.get('name'),obj.get('id')))
                print ('Found obj: %s (%s)' % (obj.get('name'), obj.get('id')))
            page_token = response.get('nextPageToken', None)
            if page_token is None:
                break
        return result
    ```
    
    google drive api를 사용하기 위해선 몇가지 절차가 필요합니다.
    
    google clood platform에 접속하여 api 등록하고 → oAuth 동의(이때 클라이언트 유형을 데스크톱으로 해야합니다) → client secret file을 받습니다. 이 파일이 있어야만 drive에 접근할 수 있습니다.
    
    스크립트 최초 실행시 oAuth 화면으로 넘어가 동의하면, 디렉토리에 token.pickle이 생깁니다. 만료되기 전까진 실행해도 oAuth화면으로 넘어가지 않습니다.
    
    [Untitled](%EC%98%A4%EB%94%94%EC%98%A4%ED%8C%8C%EC%9D%BC%20ETL%EC%9D%98%20%EC%9E%90%EB%8F%99%ED%99%94/Untitled%20875fb7ef7f33465ebb4cd832601c3689.csv)
    
    [Search for files and folders | Google Drive API | Google Developers](https://developers.google.com/drive/api/v3/search-files)
    
3. pydub의 AudioSegment를 사용해 통화시간 구하고 중앙서버에 저장
    
    window에서 개발하시는 경우, 아래 링크를 참고하시길 바랍니다.
    
    [](https://windowsloop.com/install-ffmpeg-windows-10/)
    
    ```python
    from pydub import AudioSegment
    from collections import defaultdict
    import os
    import pandas as pd
    os.chdir('')
    AudioSegment.converter = os.getcwd()+ "\\ffmpeg.exe"               
    AudioSegment.ffprobe   = os.getcwd()+ "\\ffprobe.exe"
    root_dir = os.getcwd()+"\\일별녹취"
    daily_performance, managers = [],[]
    daily_cnt = []
    data = None
    cnt = None
    for (root,dirs,files) in os.walk(root_dir):
        root_name = root.split('\\')[-1]
        if len(root_name) == 3:
            managers.append(root_name)
            daily_performance.append(data)
            daily_cnt.append(cnt)
            data = defaultdict(float)
            cnt = defaultdict(int)
    
            for file_name in files:
                sound = AudioSegment.from_file(root+'\\'+file_name)
                try:
                    year,month,day,_,_,_,_ = file_name.split('_')
                except:
                    temp = file_name.split('_')[1]
                    year,month,day = temp[:4],temp[4:6],temp[6:8]
                data[f'{year}-{month}-{day}'] += round(sound.duration_seconds/60,2)
                cnt[f'{year}-{month}-{day}'] += 1
        
    daily_performance.append(data)
    daily_cnt.append(cnt)
    
    import requests,json
    for manager,duration,cnt in zip(managers,daily_performance[1:],daily_cnt[1:]):
        data = {'manager':manager, 'durations': json.dumps(list(duration.values())), 'counts': json.dumps(list(cnt.values())), 'dates': json.dumps(list(duration.keys()))}
        requests.post('',data=data)
    ```
    
    그리고 4,5 과정의 스크립트를 매일 오전 9시에 자동으로 실행하기 위해 배치파일을 만들어 스케쥴러에 걸어주면 길고 긴 과정이 끝이 납니다!