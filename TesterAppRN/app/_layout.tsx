import React from 'react';
import {
  Alert,
  SafeAreaView,
  StyleSheet,
  ScrollView,
  View,
  Text,
  TextInput,
  StatusBar,
  TouchableOpacity,
  Button,
  Switch
} from 'react-native';

import {
  Header,
  LearnMoreLinks,
  Colors,
} from 'react-native/Libraries/NewAppScreen';

const App = () => {
  const [switchValue, setSwitchValue] = React.useState(false);

  React.useEffect(() => {
    console.log('Switch value changed:', switchValue);
  }, [switchValue]);

  return (
    <>
      <StatusBar barStyle="dark-content" />
      <SafeAreaView>
        <ScrollView
          contentInsetAdjustmentBehavior="automatic"
          style={styles.scrollView}>
          <Header />
          <View style={styles.body}>
            <View style={styles.sectionContainer}>
              <Switch testID="custom-switch" onChange={() => setSwitchValue(prev => !prev)} />
              <TextInput
                testID="custom-input"
                placeholder="Input something..."
                style={{
                  height: 40,
                  borderColor: 'gray',
                  borderWidth: 1,
                  borderRadius: 4,
                  padding: 12,
                  marginTop: 8,
                  marginBottom: 8,
                }}
              />
              <Button title="Press me to make choice" onPress={() => Alert.prompt('Make choices!')} />
              <Button title="Press me for nothing" onPress={() => true} />
            </View>
            <View style={styles.sectionContainer}>
              <TouchableOpacity delayLongPress={1000} onLongPress={() => Alert.alert('long press')}>
                <Text style={styles.sectionTitle}>Test long press (1s)</Text>
              </TouchableOpacity>
            </View>
            <LearnMoreLinks />
          </View>
        </ScrollView>
      </SafeAreaView>
    </>
  );
};

const styles = StyleSheet.create({
  scrollView: {
    backgroundColor: Colors.lighter,
  },
  engine: {
    position: 'absolute',
    right: 0,
  },
  body: {
    backgroundColor: Colors.white,
  },
  sectionContainer: {
    marginTop: 32,
    paddingHorizontal: 24,
  },
  sectionTitle: {
    fontSize: 24,
    fontWeight: '600',
    color: Colors.black,
  },
  sectionDescription: {
    marginTop: 8,
    fontSize: 18,
    fontWeight: '400',
    color: Colors.dark,
  },
  highlight: {
    fontWeight: '700',
  },
  footer: {
    color: Colors.dark,
    fontSize: 12,
    fontWeight: '600',
    padding: 4,
    paddingRight: 12,
    textAlign: 'right',
  },
});

export default App;
