import React, { useState } from 'react';
import {
  Alert,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { ExpoFocusMenuView, FocusMenuItem } from 'expo-focus-menu';

const ICON_SIZE = 20;
const ICON_COLOR = '#333';

export default function App() {
  const [lastAction, setLastAction] = useState<string>('No action yet');
  const [tapCount, setTapCount] = useState(0);

  const handleMenuItemPress = (itemId: string) => {
    setLastAction(`Menu item: ${itemId}`);
    Alert.alert('Menu Action', `You selected: ${itemId}`);
  };

  const handleReactionPress = (data: { emoji: string; selected: boolean }) => {
    const { emoji, selected } = data;
    setLastAction(selected ? `Reaction: ${emoji}` : `Removed: ${emoji}`);
  };

  // Basic menu items
  const basicMenuItems: FocusMenuItem[] = [
    { id: 'copy', title: 'Copy', icon: <Ionicons name="copy-outline" size={ICON_SIZE} color={ICON_COLOR} /> },
    { id: 'share', title: 'Share', icon: <Ionicons name="share-outline" size={ICON_SIZE} color={ICON_COLOR} /> },
    { id: 'edit', title: 'Edit', icon: <Ionicons name="pencil-outline" size={ICON_SIZE} color={ICON_COLOR} /> },
    { id: 'delete', title: 'Delete', icon: <Ionicons name="trash-outline" size={ICON_SIZE} color="#FF3B30" />, destructive: true },
  ];

  // Nested menu items
  const nestedMenuItems: FocusMenuItem[] = [
    { id: 'copy', title: 'Copy', icon: <Ionicons name="copy-outline" size={ICON_SIZE} color={ICON_COLOR} /> },
    {
      id: 'share',
      title: 'Share',
      icon: <Ionicons name="share-outline" size={ICON_SIZE} color={ICON_COLOR} />,
      children: [
        { id: 'twitter', title: 'Twitter', icon: <Ionicons name="logo-twitter" size={ICON_SIZE} color="#1DA1F2" /> },
        { id: 'facebook', title: 'Facebook', icon: <Ionicons name="logo-facebook" size={ICON_SIZE} color="#4267B2" /> },
        { id: 'email', title: 'Email', icon: <Ionicons name="mail-outline" size={ICON_SIZE} color={ICON_COLOR} /> },
      ],
    },
    { id: 'delete', title: 'Delete', icon: <Ionicons name="trash-outline" size={ICON_SIZE} color="#FF3B30" />, destructive: true },
  ];

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView style={styles.scrollView}>
        <Text style={styles.header}>Expo Focus Menu Examples</Text>

        <View style={styles.statusContainer}>
          <Text style={styles.statusLabel}>Last Action:</Text>
          <Text style={styles.statusValue}>{lastAction}</Text>
          <Text style={styles.statusLabel}>Tap Count:</Text>
          <Text style={styles.statusValue}>{tapCount}</Text>
        </View>

        {/* Example 1: Menu Only */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>1. Menu Only</Text>
          <ExpoFocusMenuView
            items={basicMenuItems}
            onItemPress={handleMenuItemPress}
            hapticFeedback={true}
          >
            <View style={styles.card}>
              <Text style={styles.cardTitle}>Basic Menu</Text>
              <Text style={styles.cardSubtitle}>Long press for options</Text>
            </View>
          </ExpoFocusMenuView>
        </View>

        {/* Example 2: Menu with Reactions */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>2. Menu with Reactions</Text>
          <ExpoFocusMenuView
            items={basicMenuItems}
            onItemPress={handleMenuItemPress}
            reactions={['❤️', '👍', '😂', '🔥', '💯', '🎉']}
            onReactionPress={handleReactionPress}
            hapticFeedback={true}
          >
            <View style={styles.card}>
              <Text style={styles.cardTitle}>With Reactions</Text>
              <Text style={styles.cardSubtitle}>React to this message</Text>
            </View>
          </ExpoFocusMenuView>
        </View>

        {/* Example 3: Nested Menu */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>3. Nested Menu</Text>
          <ExpoFocusMenuView
            items={nestedMenuItems}
            onItemPress={handleMenuItemPress}
            hapticFeedback={true}
          >
            <View style={styles.card}>
              <Text style={styles.cardTitle}>Nested Options</Text>
              <Text style={styles.cardSubtitle}>Submenus available</Text>
            </View>
          </ExpoFocusMenuView>
        </View>

        {/* Example 4: Tap Passthrough with Menu */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>4. Tap Passthrough</Text>
          <Text style={styles.description}>
            Tap to increment counter, long press for menu
          </Text>
          <ExpoFocusMenuView
            items={basicMenuItems}
            onItemPress={handleMenuItemPress}
            reactions={['👍', '❤️', '🎉']}
            onReactionPress={handleReactionPress}
            hapticFeedback={true}
          >
            <TouchableOpacity
              style={[styles.card, styles.interactiveCard]}
              onPress={() => {
                const newCount = tapCount + 1;
                setTapCount(newCount);
                setLastAction(`Tapped! Count: ${newCount}`);
              }}
              activeOpacity={0.8}
            >
              <Text style={styles.cardTitle}>Tap Me!</Text>
              <View style={styles.counter}>
                <Text style={styles.counterText}>{tapCount}</Text>
              </View>
              <Text style={styles.cardSubtitle}>
                ✓ Tap to increment{'\n'}
                ✓ Long press for menu
              </Text>
            </TouchableOpacity>
          </ExpoFocusMenuView>
        </View>

        {/* Example 5: Complex Interactive Component */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>5. Complex Interactive</Text>
          <Text style={styles.description}>
            Multiple buttons with context menu on container
          </Text>
          <ExpoFocusMenuView
            items={[
              { id: 'duplicate', title: 'Duplicate Card', icon: <Ionicons name="duplicate-outline" size={ICON_SIZE} color={ICON_COLOR} /> },
              { id: 'archive', title: 'Archive', icon: <Ionicons name="archive-outline" size={ICON_SIZE} color={ICON_COLOR} /> },
              { id: 'delete', title: 'Delete', icon: <Ionicons name="trash-outline" size={ICON_SIZE} color="#FF3B30" />, destructive: true },
            ]}
            onItemPress={handleMenuItemPress}
            hapticFeedback={true}
          >
            <View style={[styles.card, styles.complexCard]}>
              <Text style={styles.cardTitle}>Interactive Card</Text>
              <View style={styles.buttonRow}>
                <TouchableOpacity
                  style={styles.miniButton}
                  onPress={() => {
                    setLastAction('Like button pressed');
                    Alert.alert('Liked!', 'You liked this item');
                  }}
                >
                  <Text style={styles.miniButtonText}>👍 Like</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={styles.miniButton}
                  onPress={() => {
                    setLastAction('Share button pressed');
                    Alert.alert('Share', 'Opening share sheet...');
                  }}
                >
                  <Text style={styles.miniButtonText}>📤 Share</Text>
                </TouchableOpacity>
              </View>
              <Text style={styles.hint}>
                Buttons work on tap, long press anywhere for menu
              </Text>
            </View>
          </ExpoFocusMenuView>
        </View>

        <View style={styles.infoSection}>
          <Text style={styles.infoTitle}>ℹ️ Tap Passthrough Notes</Text>
          <Text style={styles.infoText}>
            • TouchableOpacity/Pressable work normally inside{'\n'}
            • Single taps are passed to child components{'\n'}
            • Long press triggers the context menu{'\n'}
            • Perfect for interactive cards and buttons{'\n'}
            • No interference between tap and long press
          </Text>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  scrollView: {
    flex: 1,
  },
  header: {
    fontSize: 28,
    fontWeight: 'bold',
    textAlign: 'center',
    marginVertical: 20,
    color: '#333',
  },
  statusContainer: {
    backgroundColor: '#fff',
    padding: 15,
    marginHorizontal: 20,
    borderRadius: 10,
    marginBottom: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  statusLabel: {
    fontSize: 12,
    color: '#666',
    marginBottom: 5,
  },
  statusValue: {
    fontSize: 16,
    fontWeight: '600',
    color: '#007AFF',
    marginBottom: 10,
  },
  section: {
    marginBottom: 30,
    paddingHorizontal: 20,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 8,
    color: '#333',
  },
  description: {
    fontSize: 13,
    color: '#666',
    marginBottom: 12,
    fontStyle: 'italic',
  },
  card: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 20,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  interactiveCard: {
    backgroundColor: '#007AFF',
  },
  complexCard: {
    alignItems: 'stretch',
  },
  cardTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    marginBottom: 5,
  },
  cardSubtitle: {
    fontSize: 13,
    color: '#666',
    fontStyle: 'italic',
    textAlign: 'center',
    lineHeight: 18,
  },
  counter: {
    width: 60,
    height: 60,
    borderRadius: 30,
    backgroundColor: 'rgba(255, 255, 255, 0.3)',
    alignItems: 'center',
    justifyContent: 'center',
    marginVertical: 15,
  },
  counterText: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#fff',
  },
  buttonRow: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginTop: 15,
    marginBottom: 10,
  },
  miniButton: {
    backgroundColor: '#007AFF',
    paddingHorizontal: 20,
    paddingVertical: 10,
    borderRadius: 20,
  },
  miniButtonText: {
    color: '#fff',
    fontSize: 14,
    fontWeight: '600',
  },
  hint: {
    fontSize: 11,
    color: '#999',
    textAlign: 'center',
    marginTop: 10,
  },
  infoSection: {
    backgroundColor: '#E8F4FD',
    margin: 20,
    padding: 15,
    borderRadius: 10,
    marginBottom: 40,
  },
  infoTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#007AFF',
    marginBottom: 8,
  },
  infoText: {
    fontSize: 13,
    color: '#005A9E',
    lineHeight: 20,
  },
});